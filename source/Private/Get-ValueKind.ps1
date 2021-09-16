function Get-ValueKind
{
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

    if (($tokens[0].Kind -eq 'LCurly' -and $tokens[-2].Kind -eq 'RCurly' -and $tokens[-1].Kind -eq 'EndOfInput') -or
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
        Write-Warning "Invoke-InvokeCommandAction: The value '$InputObject' is a literal string and cannot be expanded."
        @{
            Kind  = 'LiteralString'
            Value = $tokens.Where({ $_.Kind -eq 'StringLiteral' }).Value
        }
    }
    else
    {
        Write-Warning "Invoke-InvokeCommandAction: The value '$InputObject' could not be parsed. It is not a scriptblock nor a string."
        @{
            Kind  = 'Invalid'
            Value = $InputObject
        }
    }
}
