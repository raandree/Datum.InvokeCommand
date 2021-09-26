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

    Context 'Testing multi-role assignment' {

        It "'DSCFileWeb01' has the 'DscTagging.Layers' from both roles" {

            param ($Node, $PropertyPath, $ScriptBlock, $Value)

            $dscFileWeb01 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache

            $dscFileWeb01.DscTagging.Layers | Should -Contain 'Roles\FileServer'
            $dscFileWeb01.DscTagging.Layers | Should -Contain 'Roles\WebServer'

        }

        It "'DSCFileWeb01' has the configurations from both roles" {

            param ($Node, $PropertyPath, $ScriptBlock, $Value)

            $dscFile01 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFile01' } -IgnoreCache
            $dscWeb01 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCWeb01' } -IgnoreCache
            $dscFileWeb01 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache

            $configurations1 = $dscFile01.Configurations + $dscWeb01.Configurations | Sort-Object -Unique
            $configurations2 = $dscFileWeb01.Configurations | Sort-Object

            $configurations1 | Sort-Object | Should -Be $configurations2

        }

        It "'DSCFileWeb01' has a description reflecting all roles" {

            param ($Node, $PropertyPath, $ScriptBlock, $Value)

            $dscFileWeb01 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache

            $dscFileWeb01.Description | Should -BeLike '*FileServer*'
            $dscFileWeb01.Description | Should -BeLike '*WebServer*'

        }

    }

    AfterAll {
        Pop-Location
    }
}
