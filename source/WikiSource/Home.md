# Welcome to the Datum.InvokeCommand wiki

<sup>*Datum.InvokeCommand v#.#.#*</sup>

Here you will find all the information you need to make use of the
Datum.InvokeCommand module, including details of the functions that are
available, current capabilities and known issues, and information to help plan
a Datum-based DSC implementation using dynamic command execution.

Please leave comments, feature requests, and bug reports in the
[issues section](https://github.com/raandree/Datum.InvokeCommand/issues)
for this module.

## Overview

**Datum.InvokeCommand** is a handler module for the
[Datum](https://github.com/gaelcolas/datum/) configuration management framework.
It enables dynamic PowerShell command execution and string expansion directly
within YAML configuration data files used for PowerShell Desired State
Configuration (DSC).

### Exported Functions

- **Invoke-InvokeCommandAction**: The primary action handler invoked by the
  Datum framework. It evaluates embedded commands (script blocks and expandable
  strings) within Datum configuration values.
- **Test-InvokeCommandFilter**: The filter function called by Datum's
  `ConvertTo-Datum` on every value during data resolution. Returns `$true` when
  a value contains an embedded command that should be processed by the handler.

## Getting Started

To get started, download Datum.InvokeCommand from the
[PowerShell Gallery](https://www.powershellgallery.com/packages/Datum.InvokeCommand/)
and then unzip it to one of your PowerShell modules folders
(such as `$env:ProgramFiles\WindowsPowerShell\Modules`).

To install from the PowerShell Gallery using PowerShellGet (in PowerShell 5.0),
run the following command:

```powershell
Find-Module -Name Datum.InvokeCommand -Repository PSGallery | Install-Module
```

Or with PowerShellGet v3+:

```powershell
Install-PSResource -Name Datum.InvokeCommand
```

To confirm installation, run the below command and ensure you see the
Datum.InvokeCommand functions available:

```powershell
Get-Command -Module Datum.InvokeCommand
```

### Requirements

- **PowerShell** 4.0 or later (Windows PowerShell or PowerShell 7+)
- **[Datum](https://github.com/gaelcolas/datum/)** module (0.40.0 or later
  recommended)

### Quick Start

1. Register the handler in your `Datum.yml` configuration file:

    ```yaml
    DatumHandlers:
      Datum.InvokeCommand::InvokeCommand:
        SkipDuringLoad: true
    ```

2. Use embedded commands in your YAML configuration files:

    ```yaml
    # Script block
    NodeName: '[x={ $Node.Name }=]'

    # Expandable string
    Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
    ```

3. Resolve the configuration:

    ```powershell
    Import-Module -Name datum
    Import-Module -Name Datum.InvokeCommand

    $datum = New-DatumStructure -DefinitionFile .\DscConfigData\Datum.yml
    $rsop = Get-DatumRsop -Datum $datum -AllNodes $allNodes
    ```

For a detailed walkthrough, see the [Getting Started](docs/GettingStarted.md) guide.

## Documentation

- [Getting Started](docs/GettingStarted.md) — Step-by-step tutorial for new users.
- [Architecture](docs/Architecture.md) — Internal processing pipeline, module
  components, and error handling strategy.
- [Troubleshooting](docs/Troubleshooting.md) — Common issues, diagnostic steps,
  and resolution guidance.

## Change Log

A full list of changes in each version can be found in the
[change log](https://github.com/raandree/Datum.InvokeCommand/blob/main/CHANGELOG.md).
