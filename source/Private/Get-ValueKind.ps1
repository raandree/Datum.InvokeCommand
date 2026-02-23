function Get-ValueKind
{
    <#
    .SYNOPSIS
    Determines the type of a parsed Datum command content string.

    .DESCRIPTION
    This internal function uses the PowerShell parser to analyze the input string extracted
    from a Datum embedded command and determines its kind. The input is the content between
    the header and footer delimiters (e.g., the part between `[x=` and `=]`).

    The function returns a hashtable with `Kind` and `Value` keys. The possible kinds are:

    - **ScriptBlock**: The content is wrapped in curly braces `{ ... }`. The script block
      will be invoked by the caller. Example: `{ Get-Date }`
    - **ExpandableString**: The content is a double-quoted string `"..."` that may contain
      variable references or sub-expressions. It will be expanded using
      `$ExecutionContext.InvokeCommand.ExpandString()`. Example: `"$($Node.Name)"`
    - **LiteralString**: The content is a single-quoted string `'...'`. It cannot be expanded
      and is returned as-is with a warning. Example: `'literal value'`

    If the input does not match any recognized pattern, an error is written.

    .PARAMETER InputObject
    The raw content string extracted from the embedded command (the text between header and
    footer delimiters). Must not be null or empty.

    .EXAMPLE
    Get-ValueKind -InputObject '{ Get-Date }'

    Returns `@{ Kind = 'ScriptBlock'; Value = '{ Get-Date }' }`.

    .EXAMPLE
    Get-ValueKind -InputObject '"Hello $Name"'

    Returns `@{ Kind = 'ExpandableString'; Value = 'Hello $Name' }`.

    .EXAMPLE
    Get-ValueKind -InputObject "'literal'"

    Returns `@{ Kind = 'LiteralString'; Value = 'literal' }` and writes a warning.

    .NOTES
    This is a private function and is not exported by the module.

    .LINK
    Invoke-InvokeCommandAction
    #>
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputObject
    )

    $errors = $null
    $tokens = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $InputObject,
        [ref]$tokens,
        [ref]$errors
    )

    $InputObject = $InputObject.Trim()

    if ($InputObject -notmatch '^{[\s\S]+}$|^"[\s\S]+"$|^''[\s\S]+''$')
    {
        Write-Error 'Get-ValueKind: The input object is not an ExpandableString, nor a literal string or ScriptBlock'
    }
    elseif (($tokens[0].Kind -eq 'LCurly' -and $tokens[-2].Kind -eq 'RCurly' -and $tokens[-1].Kind -eq 'EndOfInput') -or
        ($tokens[0].Kind -eq 'LCurly' -and $tokens[-3].Kind -eq 'RCurly' -and $tokens[-2].Kind -eq 'NewLine' -and $tokens[-1].Kind -eq 'EndOfInput'))
    {
        @{
            Kind  = 'ScriptBlock'
            Value = $InputObject
        }
    }
    elseif ($tokens.Where({ $_.Kind -eq 'StringExpandable' }).Count -eq 1)
    {
        @{
            Kind  = 'ExpandableString'
            Value = $tokens.Where({ $_.Kind -eq 'StringExpandable' }).Value
        }
    }
    elseif ($tokens.Where({ $_.Kind -eq 'StringLiteral' }).Count -eq 1)
    {
        Write-Warning "Get-ValueKind: The value '$InputObject' is a literal string and cannot be expanded."
        @{
            Kind  = 'LiteralString'
            Value = $tokens.Where({ $_.Kind -eq 'StringLiteral' }).Value
        }
    }
    else
    {
        Write-Error "Get-ValueKind: The value '$InputObject' could not be parsed. It is not a scriptblock nor a string."
    }
}
