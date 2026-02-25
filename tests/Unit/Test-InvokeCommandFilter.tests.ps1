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

    Context 'Pipeline enumeration with collections' {

        It 'Returns no output when an ArrayList of OrderedDictionary objects is piped' {
            $collection = [System.Collections.ArrayList]@(
                [ordered]@{ InterfaceAlias = 'Ethernet 1'; IpAddress = '192.168.10.100' },
                [ordered]@{ InterfaceAlias = 'Ethernet 2'; IpAddress = '192.168.20.100' },
                [ordered]@{ InterfaceAlias = 'Ethernet 3'; IpAddress = '192.168.30.100' }
            )

            $result = $collection | Test-InvokeCommandFilter

            $result | Should -BeNullOrEmpty
            [bool]$result | Should -BeFalse
        }

        It 'Returns no output when a single OrderedDictionary is piped' {
            $dict = [ordered]@{ InterfaceAlias = 'Ethernet 1'; IpAddress = '192.168.10.100' }

            $result = $dict | Test-InvokeCommandFilter

            $result | Should -BeNullOrEmpty
            [bool]$result | Should -BeFalse
        }

        It 'Returns $true when a matching string is piped in a collection with non-strings' {
            $collection = @(
                [ordered]@{ Key = 'Value' },
                '[x={ Get-Date }=]',
                42
            )

            $result = $collection | Test-InvokeCommandFilter

            $result | Should -BeTrue
            [bool]$result | Should -BeTrue
        }

        It 'Returns no output when non-matching strings are piped' {
            $collection = @('plain string', 'another string', 'no command here')

            $result = $collection | Test-InvokeCommandFilter

            $result | Should -BeNullOrEmpty
            [bool]$result | Should -BeFalse
        }

        It 'Returns $false for non-string input via direct parameter binding' {
            $dict = [ordered]@{ InterfaceAlias = 'Ethernet 1' }

            $result = Test-InvokeCommandFilter -InputObject $dict

            $result | Should -BeFalse
        }

        It 'Returns $false for non-matching string via direct parameter binding' {
            $result = Test-InvokeCommandFilter -InputObject 'Just a regular string'

            $result | Should -BeFalse
        }
    }
}
