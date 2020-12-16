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
        [string]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object]
        $Node,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.IO.FileInfo]
        $File
    )

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
            if (-not $Node -and $File)
            {
                if ($File.Name -ne 'Datum.yml')
                {
                    $Node = Get-DatumCurrentNode -File $File

                    if (-not $Node)
                    {
                        return $InputObject
                    }
                }
            }

            Resolve-DatumDynamicPart -InputObject $result -DatumType $datumType
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
