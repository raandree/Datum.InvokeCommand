function Get-RelativeNodeFileName
{
    <#
    .SYNOPSIS
    Converts an absolute file path to a relative Datum node path.

    .DESCRIPTION
    This internal function takes an absolute file path and converts it to a relative path
    suitable for identifying a Datum node within the configuration hierarchy. The function:

    1. Resolves the path relative to the current location.
    2. Splits the path by backslash separators.
    3. Removes the file extension from the last segment.
    4. Returns the segments starting from the third element onward (skipping `.\` prefix
       and the root data folder name), joined with backslashes.

    For example, given a current location of `C:\Config` and a path of
    `C:\Config\DscConfigData\AllNodes\Dev\DSCFile01.yml`, the function returns
    `AllNodes\Dev\DSCFile01`.

    .PARAMETER Path
    The absolute path to the configuration file. Accepts empty strings, in which case
    an empty string is returned.

    .NOTES
    This is a private function and is not exported by the module.

    .LINK
    Invoke-InvokeCommandAction
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Path
    )

    if (-not $Path)
    {
        return [string]::Empty
    }

    try
    {
        $p = Resolve-Path -Path $Path -Relative -ErrorAction Stop
        $p = $p -split '\\'
        $p[-1] = [System.IO.Path]::GetFileNameWithoutExtension($p[-1])
        $p[2..($p.Length - 1)] -join '\'
    }
    catch
    {
        Write-Verbose 'Get-RelativeNodeFileName: nothing to catch'
    }
}
