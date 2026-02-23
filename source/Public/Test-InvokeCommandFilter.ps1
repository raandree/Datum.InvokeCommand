function Test-InvokeCommandFilter
{
    <#
    .SYNOPSIS
    Tests whether a Datum value contains an embedded command that should be processed by the
    Datum.InvokeCommand handler.

    .DESCRIPTION
    This filter function is invoked by the Datum framework's `ConvertTo-Datum` function on every
    value during data resolution. When this function returns `$true`, the Datum framework calls
    the corresponding action function `Invoke-InvokeCommandAction` to evaluate the embedded command.

    The function checks whether the input object is a string that matches the configured regular
    expression pattern for embedded commands (default pattern: `[x=` ... `=]`). The header and
    footer delimiters are defined in `Config\Datum.InvokeCommand.Config.psd1` and compiled into
    a regex at module load time.

    When the `-ReturnValue` switch is specified, the function returns the full matched string
    instead of a boolean. This is used internally by `Invoke-InvokeCommandActionInternal` to
    detect and resolve nested embedded commands.

    For more information about Datum handlers and their filter/action pattern, see
    https://github.com/gaelcolas/datum/.

    .PARAMETER InputObject
    The object to test. Only string values are evaluated against the embedded command pattern.
    Non-string objects always return `$false`. Accepts pipeline input.

    .PARAMETER ReturnValue
    When specified, returns the full matched string (including header and footer) instead of
    a boolean. Used internally for nested command resolution.

    .EXAMPLE
    Test-InvokeCommandFilter -InputObject '[x={ Get-Date }=]'

    Returns `$true` because the input string matches the embedded command pattern.

    .EXAMPLE
    Test-InvokeCommandFilter -InputObject 'Just a regular string'

    Returns `$false` because the input string does not contain an embedded command.

    .EXAMPLE
    '[x={ Get-Date }=]' | Test-InvokeCommandFilter

    Demonstrates pipeline input. Returns `$true`.

    .EXAMPLE
    Test-InvokeCommandFilter -InputObject '[x={ Get-Date }=]' -ReturnValue

    Returns the full matched string `[x={ Get-Date }=]` instead of `$true`.

    .EXAMPLE
    42 | Test-InvokeCommandFilter

    Returns `$false` because the input is not a string.

    .NOTES
    Datum handler modules follow a convention of exposing a filter function (`Test-*`) and an
    action function (`Invoke-*`). The filter function is called first to determine if the action
    should be invoked for a given value. This pattern is described in the Datum documentation.

    .LINK
    https://github.com/raandree/Datum.InvokeCommand

    .LINK
    https://github.com/gaelcolas/datum/

    .LINK
    Invoke-InvokeCommandAction
    #>
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]
        $InputObject,

        [Parameter()]
        [switch]
        $ReturnValue
    )

    process
    {
        if ($InputObject -is [string])
    {
        $all = $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['0'].Value
        $content = $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['Content'].Value

        if ($ReturnValue -and $content)
        {
            $all
        }
        elseif ($content)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        return $false
    }
    }
}
