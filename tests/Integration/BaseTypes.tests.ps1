$here = $PSScriptRoot

Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force


Describe "Testing 'ResolutionPrecedence' based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datumDefinitionFile1 = Join-Path -Path $ProjectPath\tests -ChildPath '.\Assets\DscConfigData1\Datum.yml' -Resolve
        $datumDefinitionFile2 = Join-Path -Path $ProjectPath\tests -ChildPath '.\Assets\DscConfigData2\Datum.yml' -Resolve

        $datum1 = New-DatumStructure -DefinitionFile $datumDefinitionFile1
        $datum2 = New-DatumStructure -DefinitionFile $datumDefinitionFile2

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

    Context 'Comparing static with dynamic values' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'DscTagging.Layers'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'FilesAndFolders.Items.DestinationPath'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'ComputerSettings.Credential.UserName'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'ComputerSettings.DomainName'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'ComputerSettings.JoinOU'
            }
            @{
                Node         = 'DSCDC01'
                PropertyPath = 'AddsOrgUnitsAndGroups.DomainDn'
            }
            @{
                Node         = 'DSCDC01'
                PropertyPath = 'AddsOrgUnitsAndGroups.OrgUnits.Count'
            }
            @{
                Node         = 'DSCDC01'
                PropertyPath = 'AddsDomainPrincipals.DomainDn'
            }
            @{
                Node         = 'DSCDC01'
                PropertyPath = 'AddsDomainPrincipals.Computers.Count'
            }
            @{
                Node         = 'DSCDC01'
                PropertyPath = 'AddsDomainController.SafeModeAdministratorPassword.UserName'
            }
        )

        It "Both values for Datum RSOP property '<PropertyPath>' for node '<Node>' should be equal." -TestCases $testCases {

            param ($Node, $PropertyPath, $ScriptBlock, $Value)

            $rsop1Data = Get-DatumRsopSafe -Datum $datum1 -AllNodes $configurationData1.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache
            $rsop1Data.Warnings | Should -HaveCount 0 -Because "RSOP for '$Node' (datum1/static) should not produce warnings"
            $rsop1 = $rsop1Data.Result

            $rsop2Data = Get-DatumRsopSafe -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache
            $rsop2Data.Warnings | Should -HaveCount 0 -Because "RSOP for '$Node' (datum2/dynamic) should not produce warnings"
            $rsop2 = $rsop2Data.Result

            if ($PropertyPath) {
                $cmd1 = [scriptblock]::Create("`$rsop1.$PropertyPath")
                $cmd2 = [scriptblock]::Create("`$rsop2.$PropertyPath")
            }
            else {
                $cmd1 = [scriptblock]::Create($ScriptBlock.Replace('<RsopStore>', '$rsop1'))
                $cmd2 = [scriptblock]::Create($ScriptBlock.Replace('<RsopStore>', '$rsop2'))
            }

            $result1 = & $cmd1
            $result2 = & $cmd2

            $result1 | Should -Not -BeNullOrEmpty -Because "datum1 (static) property '$PropertyPath' for node '$Node' should have a value"
            $result2 | Should -Not -BeNullOrEmpty -Because "datum2 (dynamic) property '$PropertyPath' for node '$Node' should have a value"

            if ($Value) {
                $result2 | Sort-Object | Should -Be $Value
            }
            else {
                $result1 | Sort-Object | Should -Be ($result2 | Sort-Object)
            }

        }

    }

    AfterAll {
        Pop-Location
    }
}
