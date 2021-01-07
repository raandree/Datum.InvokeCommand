function Get-RelativeNodeFileName
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )
    
    $p = Resolve-Path -Path $File.FullName -Relative
    $p = $p -split '\\'
    $p[-1] = [System.IO.Path]::GetFileNameWithoutExtension($p[-1])
    $p[2..($p.Length - 1)] -join '\'

}
