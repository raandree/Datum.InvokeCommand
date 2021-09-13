function Invoke-InvokeCommandAction
{
    <#
    .SYNOPSIS
    Call the scriptblock that is given via Datum.

    .DESCRIPTION
    When Datum uses this handler to invoke whatever script block is given to it. The returned
    data is used as configuration data.

    .PARAMETER InputObject
    Script block to invoke

    .PARAMETER Header
    Header of the Datum data string that encapsulates the script block.
    The default is [Command= but can be customized (i.e. in the Datum.yml configuration file)

    .PARAMETER Footer
    Footer of the Datum data string that encapsulates the encrypted data. The default is ]

    .EXAMPLE
    $command | Invoke-ProtectedDatumAction

    .NOTES
    The arguments you can set in the Datum.yml is directly related to the arguments of this function.

    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $Datum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object]
        $Node
    )

    if ($InputObject -is [array]) {
        $returnValue = @()
    }
    else {
        $returnValue = $null
    }

    $returnValue += foreach ($value in $InputObject) {
        if ($result = ($datumInvokeCommandRegEx.Match($InputObject).Groups['Content'].Value))
        {
            if ($datumType =
                & {
                    $errors = $null
                    $tokens = $null

                    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                        $result,
                        [ref]$tokens,
                        [ref]$errors
                    )

                    if (($tokens[0].Kind -eq 'LCurly' -and $tokens[-2].Kind -eq 'RCurly' -and $tokens[-1].Kind -eq 'EndOfInput') -or
                        ($tokens[0].Kind -eq 'LCurly' -and $tokens[-3].Kind -eq 'RCurly' -and $tokens[-2].Kind -eq 'NewLine' -and $tokens[-1].Kind -eq 'EndOfInput'))
                    {
                        'ScriptBlock'
                    }
                    elseif ($tokens |
                            & {
                                process
                                {
                                    if ($_.Kind -eq 'StringExpandable')
                                    {
                                        $_
                                    }
                                }
                            })
                    {
                        'ExpandableString'
                    }
                    else
                    {
                        $false
                    }
                })
            {
                try
                {
                    $file = Get-Item -Path $InputObject.__File -ErrorAction Ignore
                }
                catch
                {
                }

                if (-not $Node -and $file)
                {
                    if ($file.Name -ne 'Datum.yml')
                    {
                        $Node = Get-DatumCurrentNode -File $file

                        if (-not $Node)
                        {
                            return $InputObject
                        }
                    }
                }

                try
                {
                    Invoke-InvokeCommandActionInternal -InputObject $result -Datum $Datum -DatumType $datumType -ErrorAction Stop
                }
                catch
                {
                    Write-Warning ($script:localizedData.ErrorCallingInvokeInvokeCommandActionInternal -f $_.Exception.Message, $result)
                }
            }
            else
            {
                $InputObject
            }
        }
        else
        {
            $InputObject
        }
    }

    if ($InputObject -is [array]) {
        ,$returnValue
    }
    else {
        $returnValue
    }

}
