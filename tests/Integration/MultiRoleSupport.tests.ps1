$here = $PSScriptRoot

Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force

Describe "RSOP tests based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datum1 = New-DatumStructure -DefinitionFile $ProjectPath\tests\Assets\DscConfigData1\Datum.yml
        $datum2 = New-DatumStructure -DefinitionFile $ProjectPath\tests\Assets\DscConfigData2\Datum.yml

        $configurationData1 = Get-FilteredConfigurationData -Datum $datum1 -Filter {}
        $configurationData2 = Get-FilteredConfigurationData -Datum $datum2 -Filter {}

        try
        {
            #if the test is not invoked by the build script, the $ProjectPath variable does not exist
            Push-Location -Path $ProjectPath\tests\Assets\ -ErrorAction Stop
        }
        catch
        {
            Push-Location -Path .\Assets\ -ErrorAction Stop
        }
    }

    Context 'Testing multi-role assignment' {

        It "'DSCFileWeb01' has the 'DscTagging.Layers' from both roles" {

            $rsopData = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache
            $rsopData.Warnings | Should -HaveCount 0 -Because "RSOP for 'DSCFileWeb01' should not produce warnings"
            $dscFileWeb01 = $rsopData.Result

            $dscFileWeb01 | Should -Not -BeNullOrEmpty -Because 'RSOP for DSCFileWeb01 should return data'
            $dscFileWeb01.DscTagging | Should -Not -BeNullOrEmpty -Because 'DSCFileWeb01 should have DscTagging'
            $dscFileWeb01.DscTagging.Layers | Should -Not -BeNullOrEmpty -Because 'DSCFileWeb01 should have DscTagging.Layers'
            $dscFileWeb01.DscTagging.Layers | Should -Contain 'Roles\FileServer'
            $dscFileWeb01.DscTagging.Layers | Should -Contain 'Roles\WebServer'

        }

        It "'DSCFileWeb01' has the configurations from both roles" {

            $rsopFile01 = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFile01' } -IgnoreCache
            $rsopFile01.Warnings | Should -HaveCount 0 -Because "RSOP for 'DSCFile01' should not produce warnings"
            $dscFile01 = $rsopFile01.Result

            $rsopWeb01 = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCWeb01' } -IgnoreCache
            $rsopWeb01.Warnings | Should -HaveCount 0 -Because "RSOP for 'DSCWeb01' should not produce warnings"
            $dscWeb01 = $rsopWeb01.Result

            $rsopFileWeb01 = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache
            $rsopFileWeb01.Warnings | Should -HaveCount 0 -Because "RSOP for 'DSCFileWeb01' should not produce warnings"
            $dscFileWeb01 = $rsopFileWeb01.Result

            $dscFile01.Configurations | Should -Not -BeNullOrEmpty -Because 'DSCFile01 should have Configurations'
            $dscWeb01.Configurations | Should -Not -BeNullOrEmpty -Because 'DSCWeb01 should have Configurations'
            $dscFileWeb01.Configurations | Should -Not -BeNullOrEmpty -Because 'DSCFileWeb01 should have Configurations'

            $configurations1 = $dscFile01.Configurations + $dscWeb01.Configurations | Sort-Object -Unique
            $configurations2 = $dscFileWeb01.Configurations | Sort-Object

            $configurations1 | Sort-Object | Should -Be $configurations2

        }

        It "'DSCFileWeb01' has a description reflecting all roles" {

            $rsopData = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq 'DSCFileWeb01' } -IgnoreCache
            $rsopData.Warnings | Should -HaveCount 0 -Because "RSOP for 'DSCFileWeb01' should not produce warnings"
            $dscFileWeb01 = $rsopData.Result

            $dscFileWeb01 | Should -Not -BeNullOrEmpty -Because 'RSOP for DSCFileWeb01 should return data'
            $dscFileWeb01.Description | Should -Not -BeNullOrEmpty -Because 'DSCFileWeb01 should have a Description'
            $dscFileWeb01.Description | Should -BeLike '*FileServer*'
            $dscFileWeb01.Description | Should -BeLike '*WebServer*'

        }

    }

    AfterAll {
        Pop-Location
    }
}
