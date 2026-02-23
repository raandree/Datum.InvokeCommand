BeforeAll {
    Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force
    Import-Module -Name Datum.InvokeCommand -Force
}

Describe 'Test-InvokeCommandFilter tests' {

    It 'Returns $true for a valid embedded command string' {
        $result = Test-InvokeCommandFilter -InputObject '[x={ Get-Date }=]'

        $result | Should -BeTrue
    }

    It 'Returns $false for a plain string without embedded commands' {
        $result = Test-InvokeCommandFilter -InputObject 'Just a regular string'

        $result | Should -BeFalse
    }

    It 'Returns $false for a non-string input' {
        $result = Test-InvokeCommandFilter -InputObject 42

        $result | Should -BeFalse
    }

    It 'Returns $false for $null input' {
        $result = Test-InvokeCommandFilter -InputObject $null

        $result | Should -BeFalse
    }

    It 'Returns the matched string when -ReturnValue is specified' {
        $result = Test-InvokeCommandFilter -InputObject '[x={ Get-Date }=]' -ReturnValue

        $result | Should -Be '[x={ Get-Date }=]'
    }

    It 'Returns $true for an expandable string command' {
        $result = Test-InvokeCommandFilter -InputObject '[x="$($Node.Name)"=]'

        $result | Should -BeTrue
    }

    It 'Accepts pipeline input' {
        $result = '[x={ Get-Date }=]' | Test-InvokeCommandFilter

        $result | Should -BeTrue
    }
}
