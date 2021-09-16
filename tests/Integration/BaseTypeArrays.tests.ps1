$here = $PSScriptRoot

Import-Module -Name $here\TestHelpers.psm1 -Force

Describe "RSOP tests based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datumDefinitionFile1 = Join-Path -Path $here -ChildPath '.\Assets\DscConfigData1\Datum.yml' -Resolve
        $datumDefinitionFile2 = Join-Path -Path $here -ChildPath '.\Assets\DscConfigData2\Datum.yml' -Resolve

        $datum1 = New-DatumStructure -DefinitionFile $datumDefinitionFile1
        $datum2 = New-DatumStructure -DefinitionFile $datumDefinitionFile2

        $configurationData1 = Get-FilteredConfigurationData -Datum $datum1 -Filter {}
        $configurationData2 = Get-FilteredConfigurationData -Datum $datum2 -Filter {}

        try
        {
            #if the test is not invoked by the build script, the $ProjectPath variable does not exist
            Push-Location -Path $ProjectPath\tests\Integration\Assets\ -ErrorAction Stop
        }
        catch
        {
            Push-Location -Path .\Assets\ -ErrorAction Stop
        }
    }

    Context 'Comparing static with dynamic values' {

        $testCases = @(
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array1.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array1'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array1[0]'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array1[-1]'
            }

            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array2.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array2'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array2[0]'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array2[-1]'
            }

            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array3.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array3'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array3[0]'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array3[-1]'
            }

            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array4.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array4'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array4[0]'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Array4[-1]'
            }
        )

        It "Both values for Datum RSOP property '<PropertyPath>' for node '<Node>' should be equal." -TestCases $testCases {
            param ($Node, $PropertyPath, $Value)

            $rsop1 = Get-DatumRsop -Datum $datum1 -AllNodes $configurationData1.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache
            $rsop2 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache
            $cmd1 = [scriptblock]::Create("`$rsop1.$PropertyPath")
            $cmd2 = [scriptblock]::Create("`$rsop2.$PropertyPath")
            & $cmd1 | Sort-Object | Should -Be (& $cmd2 | Sort-Object)
        }

    }

    AfterAll {
        Pop-Location
    }
}