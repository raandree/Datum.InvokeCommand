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
            foreach ($propertyName in ($node.PSObject.Properties | Where-Object MemberType -EQ 'ScriptProperty').Name)
            {
                $node | ForEach-Object {
                    $newNode = $_."$propertyName"
                    if ($newNode -is [System.Collections.IDictionary])
                    {
                        if (-not $newNode.Contains('Name'))
                        {
                            if ($propertyName -eq 'AllNodes')
                            {
                                $newNode.Add('Name', '*')
                            }
                            else
                            {
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
    , @($InputObject | ForEach-Object { $_ })
}

function Get-FilteredConfigurationData
{
    param(
        [ScriptBlock]
        $Filter = {},

        [int]
        $CurrentJobNumber,

        [int]
        $TotalJobCount = 1,

        $Datum = $(Get-Variable Datum -ValueOnly -ErrorAction Stop)
    )

    $allNodes = @(Get-DatumNodesRecursive -Nodes $Datum.AllNodes -Depth 20)
    $totalNodeCount = $allNodes.Count

    if ($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create({})).ToString())
    {
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
        Datum    = $Datum
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


function Compare-Hashtable
{
    <#
    .SYNOPSIS
    Compare two Hashtable and returns an array of differences.
    .DESCRIPTION
    The Compare-Hashtable function computes differences between two Hashtables. Results are returned as
    an array of objects with the properties: "key" (the name of the key that caused a difference),
    "side" (one of "<=", "!=" or "=>"), "lvalue" an "rvalue" (resp. the left and right value
    associated with the key).
    .PARAMETER left
    The left hand side Hashtable to compare.
    .PARAMETER right
    The right hand side Hashtable to compare.
    .EXAMPLE
    Returns a difference for ("3 <="), c (3 "!=" 4) and e ("=>" 5).
    Compare-Hashtable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5}
    .EXAMPLE
    Returns a difference for a ("3 <="), c (3 "!=" 4), e ("=>" 5) and g (6 "<=").
    $left = @{ a = 1; b = 2; c = 3; f = $Null; g = 6 }
    $right = @{ b = 2; c = 4; e = 5; f = $Null; g = $Null }
    Compare-Hashtable $left $right
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Left,

        [Parameter(Mandatory = $true)]
        [hashtable]$Right
    )

    function New-Result($Key, $LValue, $Side, $RValue)
    {
        New-Object -Type PSObject -Property @{
            key    = $Key
            lvalue = $LValue
            rvalue = $RValue
            side   = $Side
        }
    }

    [object[]]$results = $Left.Keys | ForEach-Object {
        if ($Left.ContainsKey($_) -and -not $Right.ContainsKey($_))
        {
            New-Result -Key $_ -LValue $Left[$_] -Side '<=' -RValue $null
        }
        else
        {
            if ($Left[$_] -is [hashtable] -and $Right[$_] -is [hashtable] )
            {
                Compare-Hashtable -Left $Left[$_] -Right $Right[$_]
            }
            else
            {
                $LValue, $RValue = $Left[$_], $Right[$_]
                if ($LValue -ne $RValue)
                {
                    New-Result -Key $_ -LValue $LValue -Side '!=' -RValue $RValue
                }
            }
        }
    }
    $results += $Right.Keys | ForEach-Object {
        if (-not $Left.ContainsKey($_) -and $Right.ContainsKey($_))
        {
            New-Result -Key $_ -LValue $null -Side '=>' -RValue $Right[$_]
        }
    }
    if ($null -ne $Results)
    {
        $Results
    }
}
