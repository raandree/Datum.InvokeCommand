function Invoke-InvokeCommandActionInternal
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DatumType,

        [Parameter()]
        [hashtable]
        $Datum
    )

    if (-not $datum -and $DatumTree)
    {
        $datum = $DatumTree
    }

    #Prevent self-referencing loop
    if (($DatumType.Value.Contains('Get-DatumRsop')) -and ((Get-PSCallStack).Command | Where-Object { $_ -eq 'Get-DatumRsop' }).Count -gt 1)
    {
        return $DatumType.Value
    }

    try
    {
        $callId = New-Guid
        $start = Get-Date
        Write-Verbose "Invoking command '$($DatumType.Value)'. CallId is '$callId'"

        $result = if ($DatumType.Kind -eq 'ScriptBlock')
        {
            $command = [scriptblock]::Create($DatumType.Value)
            & (& $command)
        }
        elseif ($DatumType.Kind -eq 'ExpandableString')
        {
            $ExecutionContext.InvokeCommand.ExpandString($DatumType.Value)
        }
        else
        {
            $DatumType.Value
        }

        $dynamicPart = $true
        while ($dynamicPart)
        {
            if ($dynamicPart = Test-InvokeCommandFilter -InputObject $result -ReturnValue)
            {
                $innerResult = Invoke-InvokeCommandAction -InputObject $result -Datum $Datum -Node $node
                $result = $result.Replace($dynamicPart, $innerResult)
            }
        }
        $duration = (Get-Date) - $start
        Write-Verbose "Invoke with CallId '$callId' has taken $([System.Math]::Round($duration.TotalSeconds, 2)) seconds"

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
        Write-Error -Message ($script:localizedData.CannotCreateScriptBlock -f $DatumType.Value, $_.Exception.Message) -Exception $_.Exception
        return $DatumType.Value
    }
}
