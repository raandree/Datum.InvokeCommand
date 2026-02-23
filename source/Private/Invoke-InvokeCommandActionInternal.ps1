function Invoke-InvokeCommandActionInternal
{
    <#
    .SYNOPSIS
    Executes the parsed command content extracted from an embedded Datum command string.

    .DESCRIPTION
    This internal function is called by `Invoke-InvokeCommandAction` after the input has been parsed
    and its type (script block, expandable string, or literal string) has been determined by
    `Get-ValueKind`.

    Based on the `DatumType.Kind`, the function performs one of the following:
    - **ScriptBlock**: Creates and invokes the script block using `[scriptblock]::Create()`.
    - **ExpandableString**: Expands the string using `$ExecutionContext.InvokeCommand.ExpandString()`.
    - **Other** (e.g., LiteralString): Returns the value as-is.

    The function also:
    - Sets `$global:CurrentDatumNode` and `$global:CurrentDatumFile` for use within script blocks.
    - Detects and prevents self-referencing loops when `Get-DatumRsop` is involved.
    - Recursively resolves nested embedded commands by calling `Test-InvokeCommandFilter` and
      `Invoke-InvokeCommandAction` on the result.
    - Logs invocation timing for performance diagnostics via `Write-Verbose`.

    .PARAMETER DatumType
    A hashtable containing the parsed command content with the following keys:
    - `Kind`: The type of content (`ScriptBlock`, `ExpandableString`, or `LiteralString`).
    - `Value`: The raw content string to evaluate.

    .PARAMETER Datum
    The Datum structure (hashtable) providing access to the full configuration data hierarchy.
    Falls back to `$DatumTree` if not provided.

    .NOTES
    This is a private function and is not exported by the module. It is called exclusively by
    `Invoke-InvokeCommandAction`.

    .EXAMPLE
    Invoke-InvokeCommandActionInternal -DatumType @{ Kind = 'ScriptBlock'; Value = '{ Get-Date }' } -Datum $datum

    Invokes the script block and returns the current date/time.

    .LINK
    https://github.com/raandree/Datum.InvokeCommand

    .LINK
    Invoke-InvokeCommandAction
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:CurrentDatumNode')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:CurrentDatumFile')]
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
        $global:CurrentDatumNode = $Node
        $global:CurrentDatumFile = $file

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
