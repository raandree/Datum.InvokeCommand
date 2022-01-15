$here = $PSScriptRoot

Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force

Describe "RSOP tests based on 'DscWorkshopConfigData' test data" {
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
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray1.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray1.Keys'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray1.Values'
            }

            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray2.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray2.Keys'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray2.Values'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray2[2].Key'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray2[2].Value'
            }

            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray3.Count'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray3.Keys'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray3.Values'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray3[-1].Key'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'HashArray3[-1].Value'
            }


        )

        It "Both values for Datum RSOP property '<PropertyPath>' for node '<Node>' should be equal." -TestCases $testCases {

            param ($Node, $PropertyPath, $ScriptBlock, $Value)

            $rsop1 = Get-DatumRsop -Datum $datum1 -AllNodes $configurationData1.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache
            $rsop2 = Get-DatumRsop -Datum $datum2 -AllNodes $configurationData2.AllNodes -Filter { $_.Name -eq $Node } -IgnoreCache

            if ($PropertyPath) {
                $cmd1 = [scriptblock]::Create("`$rsop1.$PropertyPath")
                $cmd2 = [scriptblock]::Create("`$rsop2.$PropertyPath")
            }
            else {
                $cmd1 = [scriptblock]::Create($ScriptBlock.Replace('<RsopStore>', '$rsop1'))
                $cmd2 = [scriptblock]::Create($ScriptBlock.Replace('<RsopStore>', '$rsop2'))
            }

            if ($Value) {
                & $cmd2 | Sort-Object | Should -Be $Value
            }
            else {
                & $cmd1 | Sort-Object | Should -Be (& $cmd2 | Sort-Object)
            }

        }
    }

    AfterAll {
        Pop-Location
    }
}
