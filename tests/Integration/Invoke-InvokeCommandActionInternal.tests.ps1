$here = $PSScriptRoot

Import-Module -Name $here\TestHelpers.psm1 -Force
Import-Module -Name Datum.InvokeCommand -Force

InModuleScope Datum.InvokeCommand {

    Describe 'Invoke-InvokeCommandActionInternal tests' {

        BeforeAll {
            Mock -CommandName Write-Warning -MockWith { } -ModuleName Datum.InvokeCommand

            Import-Module -Name datum

            try
            {
                #if the test is not invoked by the build script, the $ProjectPath variable does not exist
                Push-Location -Path $ProjectPath\tests\Integration\Assets\ -ErrorAction Stop
            }
            catch
            {
                $parent = Split-Path -Path $PSCommandPath -Parent
                $parent = Join-Path -Path $parent -ChildPath Assets
                Push-Location -Path $parent -ErrorAction Stop
            }

            $datumDefinitionFile = '.\DscConfigData2\Datum.yml'
            $datum = New-DatumStructure -DefinitionFile $datumDefinitionFile
            $configurationData = Get-FilteredConfigurationData -Datum $datum -Filter {}
            $date = Get-Date
        }

        BeforeEach {
            Import-Module -Name datum
        }

        It 'Returns a datetime object' {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ Get-Date }'
            }
            $result = Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum

            $result.ToShortDateString() | Should -Be $date.ToShortDateString()

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns the invalid scriptblock' {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ Get-Date '
            }

            $result = Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum -ErrorAction SilentlyContinue -ErrorVariable e
            $e | Should -BeOfType [System.Management.Automation.ErrorRecord]

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns all node names in Datum.AllNodes using 'Get-DatumNodesRecursive'" {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ (Get-DatumNodesRecursive -Nodes $datum.AllNodes -Depth 4).Name }'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -Be $configurationData.AllNodes.Name

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns the domain name from 'Datum.Global.Adds'" {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ $datum.Global.Adds.DomainName }'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -Be $datum.Global.Adds.DomainName

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns the domain name from 'Datum.Global.Adds' (multi-line scriptblock)" {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{
                    $datum.Global.Adds.DomainName
                }'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -Be $datum.Global.Adds.DomainName

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns the domain name from 'Datum.Global.Adds' inside a string" {
            $data = @{
                Kind  = 'ExpandableString'
                Value = '"The domain name is $($datum.Global.Adds.DomainName)"'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -Be """The domain name is $($datum.Global.Adds.DomainName)"""

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns the domain name from 'Datum.Global.Adds' inside a multi-line string" {
            $data = @{
                Kind  = 'ExpandableString'
                Value = @'
"The domain name is
$($datum.Global.Adds.DomainName)"
'@
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -Be @"
"The domain name is
$($datum.Global.Adds.DomainName)"
"@
            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It "Returns null as the path 'Datum.Global.Adds.DoesNotExist' does not exist" {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ $datum.Global.Adds.DoesNotExist }'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data -Datum $datum | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns null as Datum is empty' {
            $data = @{
                Kind  = 'ScriptBlock'
                Value = '{ $datum.Global.Adds.DomainName }'
            }

            Invoke-InvokeCommandActionInternal -DatumType $data | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }
    }
}
