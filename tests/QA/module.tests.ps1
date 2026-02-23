BeforeDiscovery {
    $ProjectPath = "$PSScriptRoot\..\.." | Convert-Path
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
            $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false })
        }
    ).BaseName

    $SourcePath = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
            $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false })
        }
    ).Directory.FullName

    $mut = Import-Module -Name $ProjectName -ErrorAction Stop -PassThru -Force |
        Where-Object { $_.Path -notmatch 'ScriptsToProcess.Resolve-NodeProperty.ps1' }
    $script:allModuleFunctions = & $mut { Get-Command -Module $args[0] -CommandType Function } $ProjectName

    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)
    {
        $script:scriptAnalyzerRules = Get-ScriptAnalyzerRule
    }
    else
    {
        if ($ErrorActionPreference -ne 'Stop')
        {
            Write-Warning 'ScriptAnalyzer not found!'
        }
        else
        {
            throw 'ScriptAnalyzer not found!'
        }
    }

    $script:functionTestData = $script:allModuleFunctions | ForEach-Object {
        $functionFile = Get-ChildItem -Path $SourcePath -Recurse -Include "$($_.Name).ps1"

        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            (Get-Content -Raw $functionFile.FullName), [ref]$null, [ref]$null
        )
        $astDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $parsedFunction = $ast.FindAll($astDelegate, $true) | Where-Object Name -EQ $_.Name
        $parameters = @($parsedFunction.Body.ParamBlock.Parameters.Name.VariablePath.ForEach{ $_.ToString() })

        @{
            FunctionName     = $_.Name
            FunctionFilePath = $functionFile.FullName
            Parameters       = $parameters
        }
    }
}

BeforeAll {
    $ProjectPath = "$PSScriptRoot\..\.." | Convert-Path
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
            $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false })
        }
    ).BaseName
}

Describe 'Changelog Management' -Tag 'Changelog' {
    It 'Changelog has been updated' -Skip:(
        !([bool](Get-Command git -EA SilentlyContinue) -and
          [bool](& (Get-Process -Id $PID).Path -NoProfile -Command 'git rev-parse --is-inside-work-tree 2>$null'))
        ) {
        # Get the list of changed files compared with master
        $HeadCommit = & git rev-parse HEAD
        $MasterCommit = & git rev-parse origin/master
        $filesChanged = & git @('diff', "$MasterCommit...$HeadCommit", '--name-only')

        if ($HeadCommit -ne $MasterCommit) {
            # if we're not testing same commit (i.e. master..master)
            $filesChanged.Where{ (Split-Path $_ -Leaf) -match '^changelog' } | Should -Not -BeNullOrEmpty
        }
    }

    It 'Changelog format compliant with keepachangelog format' -Skip:(![bool](Get-Command git -EA SilentlyContinue)) {
        { Get-ChangelogData (Join-Path $ProjectPath 'CHANGELOG.md') -ErrorAction Stop } | Should -Not -Throw
    }
}

Describe 'General module control' -Tags 'FunctionalQuality' {

    It 'imports without errors' {
        { Import-Module -Name $ProjectName -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $ProjectName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $ProjectName -ErrorAction Stop } | Should -Not -Throw
        Get-Module $ProjectName | Should -BeNullOrEmpty
    }
}

Describe 'Quality for <FunctionName>' -Tags 'TestQuality' -ForEach $script:functionTestData {

    It '<FunctionName> has a unit test' {
        Get-ChildItem 'tests\' -Recurse -Include "$FunctionName.Tests.ps1" | Should -Not -BeNullOrEmpty
    }

    It 'Script Analyzer for <FunctionFilePath>' -Skip:(-not $script:scriptAnalyzerRules) {
        $PSSAResult = Invoke-ScriptAnalyzer -Path $FunctionFilePath
        $Report = $PSSAResult | Format-Table -AutoSize | Out-String -Width 110
        $PSSAResult | Should -BeNullOrEmpty -Because `
            "some rule triggered.`r`n`r`n $Report"
    }
}

Describe 'Help for <FunctionName>' -Tags 'helpQuality' -ForEach $script:functionTestData {

    BeforeAll {
        $functionFile = Get-Item -Path $FunctionFilePath
        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
            ParseInput((Get-Content -Raw $functionFile.FullName), [ref]$null, [ref]$null)
        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll($AstSearchDelegate, $true) |
            Where-Object Name -EQ $FunctionName

        $script:FunctionHelp = $ParsedFunction.GetHelpContent()
    }

    It 'Has a SYNOPSIS' {
        $script:FunctionHelp.Synopsis | Should -Not -BeNullOrEmpty
    }

    It 'Has a Description, with length > 40' {
        $script:FunctionHelp.Description.Length | Should -BeGreaterThan 40
    }

    It 'Has at least 1 example' {
        $script:FunctionHelp.Examples.Count | Should -BeGreaterThan 0
        $script:FunctionHelp.Examples[0] | Should -Match ([regex]::Escape($FunctionName))
        $script:FunctionHelp.Examples[0].Length | Should -BeGreaterThan ($FunctionName.Length + 10)
    }

    It 'Has help for Parameter: <_>' -ForEach $Parameters {
        $script:FunctionHelp.Parameters.($_.ToUpper()) | Should -Not -BeNullOrEmpty
        $script:FunctionHelp.Parameters.($_.ToUpper()).Length | Should -BeGreaterThan 25
    }
}
