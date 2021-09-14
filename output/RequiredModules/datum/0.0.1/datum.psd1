@{

    RootModule        = 'datum.psm1'

    ModuleVersion     = '0.0.1'

    GUID              = 'e176662d-46b8-4900-8de5-e84f9b4366ee'

    Author            = 'Gael Colas'

    CompanyName       = 'SynEdgy Limited'

    Copyright         = '(c) 2020 Gael Colas. All rights reserved.'

    Description       = 'Module to manage Hierarchical Configuration Data.'

    RequiredModules   = @(
        'powershell-yaml'
    )

    ScriptsToProcess  = @(
        './ScriptsToProcess/Resolve-NodeProperty.ps1'
    )

    FunctionsToExport = @('Get-DatumRsop','Get-FileProviderData','Get-MergeStrategyFromPath','Get-RelativeFileName','Invoke-TestHandlerAction','Merge-Datum','New-DatumFileProvider','New-DatumStructure','Resolve-Datum','Resolve-DatumPath','Test-TestHandlerFilter')

    AliasesToExport   = ''

    PrivateData       = @{

        PSData = @{

            Tags         = @('Datum', 'Hiera', 'DSC', 'DesiredStateConfiguration', 'hierarchical', 'ConfigurationData', 'ConfigData')

            LicenseUri   = 'https://github.com/gaelcolas/Datum/blob/master/LICENSE'

            ProjectUri   = 'https://github.com/gaelcolas/Datum/'

            ReleaseNotes = '## [0.0.1] - 2021-09-14

### Added

- Added support for specifying the encoding (#87).
- Added error handling to ''Get-FileProviderData.ps1''

### Fixed

- Fixed how issue not allowing Datum handlers to be used on arrays (#89).
- Fixed issue in Merge-Hashtable where it did not merge hashtables correctly when these
  are included in an array.
- Formatting in all files with VSCode formatting according to the ''settings.json'' file taken from Sampler
- Added yaml format config settings ''singleQuote'' and ''bracketSpacing'' and reformatted all yaml files according to the new settings.
- Cleanup
  - Get-DatumType.ps1
  - Merge-DatumArray.ps1
  - Merge-Hashtable.ps1
  - Compare-Hashtable.ps1
  - Node.ps1
  - FileProvider.ps1
  - ConvertTo-Datum.ps1
  - Get-MergeStrategyFromPath.ps1
  - Get-MergeStrategyFromString.ps1
  - Get-DatumRsop.ps1
  - Merge-Datum.ps1
  - datum.psd1
  - Get-FileProviderData.ps1
  - Invoke-TestHandlerAction.ps1
  - New-DatumStructure.ps1
  - Resolve-Datum.ps1
  - Resolve-DatumPath.ps1
  - Test-InvokeCommandFilter
  - Resolve-NodeProperty.ps1
  - New-DatumFileProvider.ps1

'

            Prerelease   = ''

        }
    }
}
