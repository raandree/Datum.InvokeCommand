# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Fix `Test-InvokeCommandFilter` emitting `$false` for every non-matching
  pipeline element in the `process` block, causing `[bool]@($false,$false,$false)`
  to evaluate as `$true` and triggering the handler on non-string collections
- Fix incorrect property name `.Key` to `.Name` in `HashArray2[2]` and
  `HashArray3[-1]` test cases in `HashArrays.tests.ps1`

### Changed

- Enhance integration tests to assert no handler warnings and non-null
  resolved values, preventing silent passes on handler failures
- Fix 4 unit tests in `Invoke-InvokeCommandAction.tests.ps1` that
  asserted an undefined `$result` variable after `Should -Throw`

### Added

- Add `Get-DatumRsopSafe` helper to `TestHelpers.psm1` that captures
  the warning stream alongside the RSOP result for test assertions
- Add pipeline collection tests for `Test-InvokeCommandFilter` to verify
  correct behavior with non-string collections and mixed input

## [0.4.0] - 2026-02-23

### Changed

- Migrated `tests/QA/module.tests.ps1` to Pester 5 syntax using
  `BeforeDiscovery`/`BeforeAll` blocks, `-ForEach` instead of `foreach`
  loops for dynamic `Describe` blocks, and updated all legacy `Should`
  assertions to use the dash-parameter syntax.
- Updated build files to newest version of Sampler (PR #12).
- Added GitHub issue templates and pull request template for better
  contribution guidelines.
- Added VSCode settings for the project.
- Updated GitVersion.Tool installation to specify version 5.*.
- Added `Agent.Source.Git.ShallowFetchDepth` variable to pipeline
  configuration.
- Added `AliasesToExport` to module manifest for better command aliasing.
- Updated Windows VM image to 'windows-latest' in Azure Pipelines
  configuration.
- Removed `PSDependOptions` from `RequiredModules.psd1` for cleaner
  configuration.
- Added `SECURITY.md` for reporting security vulnerabilities and guidelines.
- Added `codecov.yml` configuration file for coverage reporting.
- Updated `build.ps1` and `Resolve-Dependency.ps1` build scripts.
- Refactored Azure Pipelines configuration for improved artifact handling
  and test reporting.
- Updated pipeline configuration in `build.yaml`.
- Updated ModuleBuilder configuration.
- Updated dependent modules configuration.
- Added PSDepend configuration.
- Added ReleaseAssets configuration to GitHub settings.
- Updated DscResource.DocGenerator configuration.
- Reorganized `RequiredModules.psd1` for improved readability.

### Fixed

- Fix incorrect module manifest `Description` which referenced
  Datum.ProtectedData instead of describing this module's actual purpose.
- Fix PSScriptAnalyzer `PSUseProcessBlockForPipelineCommand` warning in
  `Invoke-InvokeCommandAction` and `Test-InvokeCommandFilter` by wrapping
  the function body in a `process` block.

### Removed

- **Breaking:** Remove unused parameter `ProjectPath` from
  `Invoke-InvokeCommandAction` to resolve PSScriptAnalyzer
  `PSReviewUnusedParameter` warning.

### Added

- Add comprehensive comment-based help for all public functions
  (`Invoke-InvokeCommandAction`, `Test-InvokeCommandFilter`) with detailed
  descriptions, parameter documentation, multiple examples, notes, and
  cross-reference links.
- Add comment-based help for all private functions
  (`Invoke-InvokeCommandActionInternal`, `Get-DatumCurrentNode`,
  `Get-RelativeNodeFileName`, `Get-ValueKind`).
- Add inline documentation comments to module initialization code
  in `Prefix.ps1`.
- Add comprehensive `README.md` with overview, installation instructions,
  quick start guide, full embedded command syntax reference, available
  variables, dynamic resolution precedence, nested references,
  configuration, error handling, exported functions, and a complete
  end-to-end example.
- Add `docs/GettingStarted.md` step-by-step tutorial for new users.
- Add `source/WikiSource/Home.md` wiki home page with module overview,
  exported functions, installation instructions, quick start guide,
  documentation links, and change log reference.
- Add `docs/Architecture.md` describing the internal processing pipeline,
  module components, error handling strategy, and Datum framework
  relationship.
- Add `docs/Troubleshooting.md` covering common issues, diagnostic steps,
  and resolution guidance.

## [0.3.0] - 2023-03-20

### Added

- Support for expandable strings.
- Configurable Header and Footer.
- Content is now evaluated with RegEx + PowerShell Parser.
- Gives access to Node and Datum variable.
- Added function 'Get-RelativeNodeFileName'.
- Resolves nested references.
- Added analyzersettings rules.
- Added support for multi-line ScriptBlocks.
- Added more tests and test data for multi-role support and handler support in 'ResolutionPrecedence'.
- Improved error handling and implemented '$env:DatumHandlerThrowsOnError'.
- Added parameter `ProjectPath` to `Invoke-InvokeCommandAction`.
- Updated build scripts to latest Sampler scripts.

## [0.1.1] - 2020-08-25

### Added

- Initial commit.

### Fixed

- An empty .psm1 file is required if the module manifest contain the
  property `RootModule`. If this does not exist it is not possible to
  run the build task (fails with invalid module manifest).

### Fixed
