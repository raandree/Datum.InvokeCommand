$here = $PSScriptRoot

Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force
Import-Module -Name Datum.InvokeCommand -Force

InModuleScope Datum.InvokeCommand {

    Describe 'Invoke-InvokeCommandAction tests' {

        Context '$env:DatumHandlerThrowsOnError == $false' {

            BeforeAll {
                Mock -CommandName Write-Warning -MockWith { }
                Mock -CommandName Write-Error -MockWith { }
                $env:DatumHandlerThrowsOnError = $false

                Import-Module -Name datum

                try
                {
                    #if the test is not invoked by the build script, the $ProjectPath variable does not exist
                    Push-Location -Path $ProjectPath\tests\Assets\ -ErrorAction Stop
                }
                catch
                {
                    $parentPath = Split-Path -Path $PSCommandPath -Parent
                    $testsPath = Split-Path -Path $parentPath -Parent
                    $assetsPath = Join-Path -Path $testsPath -ChildPath Assets
                    Push-Location -Path $assetsPath -ErrorAction Stop
                }

                $datumDefinitionFile = '.\DscConfigData2\Datum.yml'
                $datum = New-DatumStructure -DefinitionFile $datumDefinitionFile
                $configurationData = Get-FilteredConfigurationData -Datum $datum -Filter {}
                $date = Get-Date
            }

            BeforeEach {
                Import-Module -Name datum
            }

            It 'Returns a datetime object, intact ScriptBlock' {
                $inputObject = '[x= { Get-Date } =]'

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -BeOfType [datetime]

                Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
            }

            It 'Returns a datetime object, intact multi-line ScriptBlock)' {
                $inputObject = '[x= {
                Get-Date
            } =]'

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -BeOfType [datetime]

                Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
            }

            It 'Invalid ScriptBlock, returns $null and writes an error' {
                $inputObject = '[x={ Get-Date =]'

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -Be $inputObject

                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
            }

            It 'Returns $InputObject and writes an error due to broken multi-line ScriptBlock)' {
                $inputObject = '[x= {
                Get-Date
            =]'

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -Be $inputObject

                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
            }

            It 'Returns $InputObject and writes an error due to broken multi-line Input)' {
                $inputObject = @'
[x= {
    Get-Date
} =
'@

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -Be $inputObject

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

            It 'Returns the InputObject, broken multi-line string' {
                $date = Get-Date
                $env:DatumHandlerThrowsOnError = $false
                $inputObject = @'
[x="Current year is $((Get-Date).Year)
Current month is $((Get-Date).Month)=]'
'@

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -Be @'
[x="Current year is $((Get-Date).Year)
Current month is $((Get-Date).Month)=]'
'@

                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
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

        Context '$env:DatumHandlerThrowsOnError == $true' {

            BeforeAll {
                Mock -CommandName Write-Warning -MockWith { }
                $env:DatumHandlerThrowsOnError = $true

                Import-Module -Name datum

                try
                {
                    #if the test is not invoked by the build script, the $ProjectPath variable does not exist
                    Push-Location -Path $ProjectPath\tests\Assets\ -ErrorAction Stop
                }
                catch
                {
                    $parentPath = Split-Path -Path $PSCommandPath -Parent
                    $testsPath = Split-Path -Path $parentPath -Parent
                    $assetsPath = Join-Path -Path $testsPath -ChildPath Assets
                    Push-Location -Path $assetsPath -ErrorAction Stop
                }

                $datumDefinitionFile = '.\DscConfigData2\Datum.yml'
                $datum = New-DatumStructure -DefinitionFile $datumDefinitionFile
                $configurationData = Get-FilteredConfigurationData -Datum $datum -Filter {}
                $date = Get-Date
            }

            BeforeEach {
                Import-Module -Name datum
            }

            It 'Invalid Input returns $null and throws an error' {
                $inputObject = '[x={ Get-Date ='

                { Invoke-InvokeCommandAction -InputObject $inputObject } | Should -Throw
                $result | Should -BeNullOrEmpty
            }

            It 'Invalid ScriptBlock, returns $null and throws an error' {
                $inputObject = '[x={ Get-Date =]'

                { Invoke-InvokeCommandAction -InputObject $inputObject } | Should -Throw
                $result | Should -BeNullOrEmpty
            }

            It 'Invalid ScriptBlock, returns $null and throws an error' {
                $inputObject = @'
[x={
Get-Date =]
'@

                { Invoke-InvokeCommandAction -InputObject $inputObject } | Should -Throw
                $result | Should -BeNullOrEmpty
            }

            It 'Invalid multi-line string, returns $null and throws an error' {
                $date = Get-Date
                $inputObject = @'
[x="Current year is $((Get-Date).Year)
Current month is $((Get-Date).Month)=]'
'@

                { Invoke-InvokeCommandAction -InputObject $inputObject } | Should -Throw
                $result | Should -BeNullOrEmpty
            }

            It 'Literal String returns $null and throws an error' {
                $inputObject = "[x='Get-Date'=]"

                $result = Invoke-InvokeCommandAction -InputObject $inputObject
                $result | Should -Be 'Get-Date'

                Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
            }
        }
    }
}
