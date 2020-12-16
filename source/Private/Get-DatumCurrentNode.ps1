function Get-DatumCurrentNode
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $fileNode = $File | Get-Content | ConvertFrom-Yaml
    $rsopNode = Get-DatumRsop -Datum $datum -AllNodes $currentNode

    if ($rsopNode)
    {
        $rsopNode
    }
    else
    {
        $fileNode
    }
}
