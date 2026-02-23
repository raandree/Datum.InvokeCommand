function Get-DatumCurrentNode
{
    <#
    .SYNOPSIS
    Resolves the current Datum node from a YAML configuration file.

    .DESCRIPTION
    This internal function determines the current node context when processing a Datum
    configuration file. It reads the YAML file content, converts it, and then attempts
    to resolve the full RSOP (Resultant Set of Policy) for the node using `Get-DatumRsop`.

    If the RSOP resolution succeeds, the resolved node data is returned. Otherwise, the
    raw file content is returned as a fallback.

    This function is used by `Invoke-InvokeCommandAction` to automatically determine the
    `$Node` context when it is not explicitly provided and the value originates from a
    node-specific file (not `Datum.yml`).

    .PARAMETER File
    The YAML configuration file (`System.IO.FileInfo`) to read and resolve the node from.

    .NOTES
    This is a private function and is not exported by the module.

    .EXAMPLE
    Get-DatumCurrentNode -File (Get-Item 'C:\Config\DscConfigData\AllNodes\Dev\DSCFile01.yml')

    Returns the resolved node data for 'DSCFile01' by reading the YAML file and
    performing an RSOP resolution.

    .LINK
    Invoke-InvokeCommandAction
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $File
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
