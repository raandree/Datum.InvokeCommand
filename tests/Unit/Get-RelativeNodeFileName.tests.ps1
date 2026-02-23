BeforeAll {
    Import-Module -Name $ProjectPath\tests\TestHelpers.psm1 -Force
    Import-Module -Name Datum.InvokeCommand -Force
}

InModuleScope Datum.InvokeCommand {

    Describe 'Get-RelativeNodeFileName tests' {

        It 'Returns an empty string when the path is empty' {
            $result = Get-RelativeNodeFileName -Path ''

            $result | Should -Be ([string]::Empty)
        }

        It 'Returns a relative node path from an absolute path' {
            Push-Location -Path TestDrive:\

            $dir = New-Item -Path 'TestDrive:\DscConfigData\AllNodes\Dev' -ItemType Directory -Force
            $file = New-Item -Path "$($dir.FullName)\DSCFile01.yml" -ItemType File -Force

            $result = Get-RelativeNodeFileName -Path $file.FullName

            $result | Should -Be 'AllNodes\Dev\DSCFile01'

            Pop-Location
        }

        It 'Removes the file extension from the last segment' {
            Push-Location -Path TestDrive:\

            $dir = New-Item -Path 'TestDrive:\DscConfigData\AllNodes' -ItemType Directory -Force
            $file = New-Item -Path "$($dir.FullName)\Server01.yml" -ItemType File -Force

            $result = Get-RelativeNodeFileName -Path $file.FullName

            $result | Should -Not -Match '\.yml$'

            Pop-Location
        }
    }
}
