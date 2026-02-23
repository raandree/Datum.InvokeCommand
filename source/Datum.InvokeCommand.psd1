@{

    RootModule        = 'Datum.InvokeCommand.psm1'

    ModuleVersion     = '0.0.1'

    GUID              = '31b6472c-069c-40c2-aaa9-ac8c2de55081'

    Author            = 'Raimund Andree'

    CompanyName       = 'NA'

    Copyright         = '(c) 2019 Raimund Andree. All rights reserved.'

    Description       = 'Datum Handler module to dynamically invoke PowerShell commands and expand strings within Datum configuration data. Enables embedding script blocks and expandable strings in YAML configuration files for DSC (Desired State Configuration) data resolution.'

    FunctionsToExport = 'Invoke-InvokeCommandAction', 'Test-InvokeCommandFilter'

    AliasesToExport   = @()

    PowerShellVersion = '4.0'

    PrivateData       = @{

        PSData = @{

            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'Datum')

            LicenseUri   = 'https://github.com/raandree/Datum.InvokeCommand/blob/master/LICENSE'

            ProjectUri   = 'https://github.com/raandree/Datum.InvokeCommand'

            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            Prerelease   = ''

            ReleaseNotes = ''

        }

    }

}
