function Get-RelativeNodeFileName
{
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
