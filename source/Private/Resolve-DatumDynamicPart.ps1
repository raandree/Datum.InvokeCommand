function Resolve-DatumDynamicPart
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ExpandableString', 'ScriptBlock')]
        [string]$DatumType
    )

    if (-not $datum -and -not $DatumTree)
    {
        return $InputObject
    }
    elseif (-not $datum -and $DatumTree)
    {
        $datum = $DatumTree
    }

    if ((Get-PSCallStack | Select-Object -Skip 1).Command -contains $MyInvocation.MyCommand.Name)
    {
        return $InputObject
    }

    try
    {
        $command = [scriptblock]::Create($InputObject)
        $result = if ($DatumType -eq 'ScriptBlock')
        {
            & (& $command)
        }
        else
        {
            & $command
        }

        if ($result -is [string])
        {
            $ExecutionContext.InvokeCommand.ExpandString($result)
        }
        else
        {
            $result
        }
    }
    catch
    {
        Write-Error -Message ($script:localizedData.CannotCreateScriptBlock -f $InputObject, $_.Exception.Message)
        return $InputObject
    }
}
