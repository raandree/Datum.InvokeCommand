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

    Context 'Base-Type array merge behavior' {

        $testCases = @(
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'NodeName'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'Environment'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'Description'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'ComputerSettings.Name'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'ComputerSettings.Description'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'NetworkIpConfiguration.Interfaces[0].IpAddress'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'NetworkIpConfiguration.Interfaces[0].Gateway'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'NetworkIpConfiguration.Interfaces[0].DnsServer[0]'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'LcmConfig.ConfigurationRepositoryWeb.Server.ConfigurationNames'
            #}
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'DscTagging.Layers'
            }
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'ComputerSettings.DomainName'
            #}
            #@{
            #    Node         = 'DSCFile01'
            #    PropertyPath = 'ComputerSettings.JoinOU'
            #}
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
