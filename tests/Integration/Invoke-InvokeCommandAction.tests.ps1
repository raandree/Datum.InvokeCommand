$here = $PSScriptRoot

Import-Module -Name $here\TestHelpers.psm1 -Force
Import-Module -Name Datum.InvokeCommand -Force

InModuleScope Datum.InvokeCommand {

    Describe 'Invoke-InvokeCommandAction tests' {

        BeforeAll {
            Mock -CommandName Write-Warning -MockWith { } #-ModuleName Datum.InvokeCommand

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
            $inputObject = '[x= { Get-Date } =]'

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            $result | Should -BeOfType [datetime]

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns a datetime object (multi-line scriptblock)' {
            $inputObject = '[x= {
                Get-Date
            } =]'

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            $result | Should -BeOfType [datetime]

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns the invalid scriptblock' {
            $inputObject = '[x={ Get-Date =]'

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            $result | Should -Be '{ Get-Date '

            Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
        }

        It 'Returns a datetime object (multi-line string)' {
            $date = Get-Date
            $inputObject = @'
[x="Current year is $((Get-Date).Year)
Current month is $((Get-Date).Month)"=]'
'@

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            $result | Should -Be @"
Current year is $((Get-Date).Year)
Current month is $((Get-Date).Month)
"@

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns a hashtable ' {
            $inputObject = '[x= { @{ Name = "Name1"; Value = "Value1" } } =]'
            $hashtable = @{
                Name  = 'Name1'
                Value = 'Value1'
            }

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            Compare-Hashtable -Left $result -Right $hashtable | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns a hashtable (multi-line scriptblock)' {
            $inputObject = '[x= {
                @{
                    Name = "Name1"
                    Value = "Value1"
                }
            } =]'
            $hashtable = @{
                Name  = 'Name1'
                Value = 'Value1'
            }

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            Compare-Hashtable -Left $result -Right $hashtable | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns a hashtable array' {
            $inputObject = '[x= { 1..10 | ForEach-Object { @{ Name = "Name$_"; Value = "Value$_" } } } =]'
            $hashtables = 1..10 |
                ForEach-Object {
                    @{
                        Name  = "Name$_"
                        Value = "Value$_"
                    }
                }

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            for ($i = 0; $i -lt $Hashtables.Count - 1; $i++)
            {
                Compare-Hashtable -Left $result[$i] -Right $hashtables[$i] | Should -BeNullOrEmpty
            }

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Returns a hashtable array (multi-line scriptblock)' {
            $inputObject = '[x= {
                1..10 |
                ForEach-Object {
                    @{
                        Name = "Name$_"
                        Value = "Value$_"
                    }
                }
            } =]'
            $hashtables = 1..10 |
                ForEach-Object {
                    @{
                        Name  = "Name$_"
                        Value = "Value$_"
                    }
                }

            $result = Invoke-InvokeCommandAction -InputObject $inputObject
            for ($i = 0; $i -lt $Hashtables.Count - 1; $i++)
            {
                Compare-Hashtable -Left $result[$i] -Right $hashtables[$i] | Should -BeNullOrEmpty
            }

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

    }
}
