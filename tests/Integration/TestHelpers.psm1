function Get-DatumNodesRecursive
{
    param(
        [object[]]$Nodes,

        [int]$Depth
    )

    if ($Depth -gt 0)
    {
        $expandedNodes = foreach ($node in $Nodes)
        {
            foreach ($propertyName in ($node.PSObject.Properties | Where-Object MemberType -eq 'ScriptProperty').Name)
            {
                $node | ForEach-Object {
                    $newNode = $_."$propertyName"
                    if ($newNode -is [System.Collections.IDictionary]) {
                        if (-not $newNode.Contains('Name')) {
                            if ($propertyName -eq 'AllNodes') {
                                $newNode.Add('Name', '*')
                            }
                            else {
                                $newNode.Add('Name', $propertyName)
                            }
                        }

                        [hashtable]$newNode
                    }
                    else
                    {
                        $newNode
                    }
                }
            }
        }

        if ($expandedNodes)
        {
            $expandedNodes = FlattenArray -InputObject $expandedNodes
            $Depth--
            $expandedNodes | Where-Object { $_ -is [System.Collections.IDictionary] }
            Get-DatumNodesRecursive -Nodes $expandedNodes -Depth $Depth
        }
        else
        {
            $Depth = 0
        }
    }
}

function FlattenArray
{
    param (
        [Parameter(Mandatory)]
        [array]$InputObject
    )
    ,@($InputObject | ForEach-Object { $_ })
}

function Get-FilteredConfigurationData {
    param(
        [ScriptBlock]
        $Filter = {},

        [int]
        $CurrentJobNumber,

        [int]
        $TotalJobCount = 1,

        $Datum = $(Get-variable Datum -ValueOnly -ErrorAction Stop)
    )

    $allNodes = @(Get-DatumNodesRecursive -Nodes $Datum.AllNodes -Depth 20)
    $totalNodeCount = $allNodes.Count

    if($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create({})).ToString()) {
        Write-Host "Filter: $($Filter.ToString())"
        $allNodes = [System.Collections.Hashtable[]]$allNodes.Where($Filter)
        Write-Host "Node count after applying filter: $($allNodes.Count)"
    }

    if (-not $allNodes.Count)
    {
        Write-Error "No node data found. There are in total $totalNodeCount nodes defined, but no node was selected. You may want to verify the filter: '$Filter'."
    }

    $CurrentJobNumber--
    $allNodes = Split-Array -List $allNodes -ChunkCount $TotalJobCount
    $allNodes = $allNodes[$CurrentJobNumber]

    return @{
        AllNodes = $allNodes
        Datum = $Datum
    }
}

function Split-Array
{
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$List,

        [Parameter(Mandatory, ParameterSetName = 'ChunkSize')]
        [int]$ChunkSize,

        [Parameter(Mandatory, ParameterSetName = 'ChunkCount')]
        [int]$ChunkCount
    )
    $aggregateList = @()

    if ($ChunkCount)
    {
        $ChunkSize = [Math]::Ceiling($List.Count / $ChunkCount)
    }

    $blocks = [Math]::Floor($List.Count / $ChunkSize)
    $leftOver = $List.Count % $ChunkSize
    for ($i = 0; $i -lt $blocks; $i++)
    {
        $end = $ChunkSize * ($i + 1) - 1

        $aggregateList += @(, $List[$start..$end])
        $start = $end + 1
    }
    if ($leftOver -gt 0)
    {
        $aggregateList += @(, $List[$start..($end + $leftOver)])
    }

    , $aggregateList
}
