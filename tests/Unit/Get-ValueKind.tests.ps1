$here = $PSScriptRoot

Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force
Import-Module -Name Datum.InvokeCommand -Force

InModuleScope Datum.InvokeCommand {

    Describe "Get-ValueKind Parsing tests" {

        BeforeAll {
            Mock -CommandName Write-Error -MockWith { } -ModuleName Datum.InvokeCommand
            Mock -CommandName Write-Warning -MockWith { } -ModuleName Datum.InvokeCommand
        }

        It 'Valid expandable string' {
            $result = Get-ValueKind -InputObject '"string"'

            $result.Value | Should -Be 'string'
            $result.Kind | Should -Be 'ExpandableString'

            Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
        }

        It 'Invalid string' {
            $result = Get-ValueKind -InputObject 'string'

            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }

        It 'Invalid string' {
            $result = Get-ValueKind -InputObject 'string"'

            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }

        It 'Valid literal string' {
            $result = Get-ValueKind -InputObject "'string'"

            $result.Value | Should -Be 'string'
            $result.Kind | Should -Be 'LiteralString'

            Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
        }

        It 'Invalid literal string' {
            $result = Get-ValueKind -InputObject "'string"

            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }

        #------------------------------------------------------------------------------

        It 'Valid script block 1' {
            $result = Get-ValueKind -InputObject '{ Get-Date }'

            $result.Value | Should -Be '{ Get-Date }'
            $result.Kind | Should -Be 'Scriptblock'

            Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
        }

        It 'Valid multi-line script block 1' {
            $result = Get-ValueKind -InputObject @'
{
    Get-Date
}
'@
            $result.Value | Should -Be @'
{
    Get-Date
}
'@
            $result.Kind | Should -Be 'Scriptblock'

            Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
        }

        It 'Invalid multi-line script block 1' {
            $result = Get-ValueKind -InputObject @'
{
    Get-Date
'@
            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }

        It 'Valid script block 2' {
            $result = Get-ValueKind -InputObject '{ Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5 }'

            $result.Value | Should -Be "{ Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5 }"
            $result.Kind | Should -Be 'Scriptblock'

            Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
        }

        It 'Invalid script block 1' {
            $result = Get-ValueKind -InputObject '{ Get-Process '

            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }

        It 'Invalid script block 2' {
            $result = Get-ValueKind -InputObject 'Get-Process }'

            $result.Value | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }
    }
}
