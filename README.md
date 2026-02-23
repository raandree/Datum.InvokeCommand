# Datum.InvokeCommand

[![Build Status](https://dev.azure.com/RaijinCluster/Datum.InvokeCommand/_apis/build/status/raandree.Datum.InvokeCommand?branchName=main)](https://dev.azure.com/RaijinCluster/Datum.InvokeCommand/_build/latest?definitionId=7&branchName=main)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Datum.InvokeCommand)](https://www.powershellgallery.com/packages/Datum.InvokeCommand)
[![License](https://img.shields.io/github/license/raandree/Datum.InvokeCommand)](https://github.com/raandree/Datum.InvokeCommand/blob/main/LICENSE)

A [Datum](https://github.com/gaelcolas/datum/) handler module that enables dynamic command execution and string expansion within Datum configuration data for PowerShell Desired State Configuration (DSC).

## Overview

**Datum.InvokeCommand** extends the [Datum](https://github.com/gaelcolas/datum/) configuration management framework by allowing you to embed PowerShell script blocks and expandable strings directly in your YAML configuration files. Instead of hard-coding values, you can dynamically compute configuration data at resolution time.

This is particularly useful for:

- **Avoiding data duplication** by referencing other parts of the Datum hierarchy (e.g., `$Datum.Global.Adds.DomainName`)
- **Computing values dynamically** using PowerShell expressions (e.g., `{ Get-Date }`)
- **Building strings from node context** using variable expansion (e.g., `"$($Node.Name) in $($Node.Environment)"`)
- **Cross-referencing nodes** and generating data from the full configuration tree
- **Supporting multi-role assignments** by dynamically resolving `ResolutionPrecedence` paths

For the Datum framework documentation, architecture overview, and handler concepts, refer to the [Datum project](https://github.com/gaelcolas/datum/).

## Requirements

- **PowerShell** 4.0 or later (Windows PowerShell or PowerShell 7+)
- **[Datum](https://github.com/gaelcolas/datum/)** module (0.40.0 or later recommended)
- **[DscResource.Common](https://github.com/dsccommunity/DscResource.Common)** module (bundled)

## Installation

Install from the PowerShell Gallery:

```powershell
Install-Module -Name Datum.InvokeCommand
```

Or with PowerShellGet v3+:

```powershell
Install-PSResource -Name Datum.InvokeCommand
```

## Quick Start

### 1. Register the Handler in Datum.yml

Add the `Datum.InvokeCommand` handler to your `Datum.yml` configuration file:

```yaml
DatumHandlers:
  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true
```

> **Important**: The `SkipDuringLoad: true` flag is required. It prevents the handler from
> being invoked during the initial Datum structure loading. Commands are only evaluated during
> value resolution (e.g., when computing RSOP - Resultant Set of Policy).

### 2. Use Embedded Commands in YAML Files

Wrap your commands with the configurable delimiters (default: `[x=` and `=]`):

**Script blocks** (curly braces):

```yaml
NodeName: '[x={ $Node.Name }=]'
Environment: '[x={ $File.Directory.Name }=]'
```

**Expandable strings** (double quotes):

```yaml
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
IpAddress: '[x= "$($Datum.Global.Network.IP.Subnet1).$($Node.IpNumber)" =]'
```

### 3. Resolve the Configuration

```powershell
Import-Module -Name datum
Import-Module -Name Datum.InvokeCommand

$datum = New-DatumStructure -DefinitionFile .\DscConfigData\Datum.yml
$rsop = Get-DatumRsop -Datum $datum -AllNodes $allNodes
```

Embedded commands are automatically evaluated during RSOP resolution.

## Embedded Command Syntax

All embedded commands are wrapped with header and footer delimiters. The default delimiters are `[x=` (header) and `=]` (footer). These can be customized in the module configuration file (`Config\Datum.InvokeCommand.Config.psd1`).

### Script Blocks

Use curly braces `{ }` inside the delimiters to define a PowerShell script block. The script block is invoked and its output becomes the configuration value.

```yaml
# Simple command
NodeName: '[x={ $Node.Name }=]'

# Complex expression
Computers: '[x={ Get-DatumNodesRecursive -Nodes $Datum.AllNodes -Depth 4 |
    Where-Object { $_.Name -like "*Web*" } |
    ForEach-Object { @{ ComputerName = $_.Name } } }=]'

# Return a hashtable
Credential: '[x={ $Datum.Global.Adds.DomainAdminCredential }=]'

# Multi-line script block
DomainDn: |
  [x={
    $parts = $Datum.Global.Adds.DomainFqdn -split '\.'
    $parts | ForEach-Object { "DC=$_" } | Join-String -Separator ','
  }=]
```

Script blocks can return **any PowerShell object type**: strings, integers, dates, hashtables, arrays, PSCredential objects, and more.

### Expandable Strings

Use double quotes `" "` inside the delimiters for PowerShell string expansion. Variables and sub-expressions are expanded at resolution time.

```yaml
# Variable expansion
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'

# Sub-expression with Datum lookup
IpAddress: '[x= "$($Datum.Global.Network.IP.Subnet1).$($Node.IpNumber)" =]'
Gateway: '[x= "$($Datum.Global.Network.IP.Subnet1).50" =]'

# Multi-line expandable string
Message: '[x="Server $($Node.Name) is
  located in $($Node.Location)"=]'
```

### Literal Strings

Single-quoted strings `' '` are returned as-is and cannot be expanded. A warning is emitted when a literal string is encountered.

```yaml
# This will return 'Get-Date' as a string, not a date - a warning is emitted
Value: "[x='Get-Date'=]"
```

## Available Variables in Embedded Commands

Inside script blocks and expandable strings, the following variables are automatically available:

| Variable | Description |
|----------|-------------|
| `$Node` | The current node's configuration data (resolved from the YAML file or RSOP). |
| `$Datum` | The full Datum configuration hierarchy, enabling lookups like `$Datum.Global.Adds.DomainName`. |
| `$File` | The `System.IO.FileInfo` object representing the current YAML file being processed. |

### Using $Node

The `$Node` variable provides access to the current node's properties:

```yaml
# In AllNodes/Dev/DSCFile01.yml
NodeName: '[x={ $Node.Name }=]'              # Returns 'DSCFile01'
Environment: '[x={ $File.Directory.Name }=]'  # Returns 'Dev'
Role: FileServer
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'  # Returns 'FileServer in Dev'
```

### Using $Datum

The `$Datum` variable provides access to the entire configuration hierarchy:

```yaml
# Reference global configuration
DomainName: '[x={ $Datum.Global.Adds.DomainFqdn }=]'
DomainDn: '[x="$($Datum.Global.Adds.DomainDn)"=]'

# Use Datum lookups in complex expressions
DnsServer:
  - '[x= "$($Datum.Global.Network.IP.Subnet1).10" =]'
```

### Using $File

The `$File` variable represents the current YAML file being processed:

```yaml
# Get the directory name (often used for environment)
Environment: '[x={ $File.Directory.Name }=]'

# Get the source file path for tagging
DscTagging:
  Layers:
    - '[x={ Get-DatumSourceFile -Path $File }=]'
```

## Dynamic Resolution Precedence

One of the most powerful features of Datum.InvokeCommand is the ability to use embedded commands in the `ResolutionPrecedence` section of `Datum.yml`. This enables dynamic lookup paths:

```yaml
ResolutionPrecedence:
  - AllNodes\$($Node.Environment)\$($Node.NodeName)
  - '[x= "Environment\$($Node.Environment)" =]'
  - Locations\$($Node.Location)
  - '[x={ $Node.Role | ForEach-Object { "Roles\$_" } } =]'
  - Baselines\Security
  - Baselines\$($Node.Baseline)
  - Baselines\DscLcm
```

The handler for `ResolutionPrecedence` in the example above enables **multi-role support**: when a node has multiple roles (e.g., `Role: [FileServer, WebServer]`), the script block dynamically generates multiple role paths, and configuration from all roles is merged according to the Datum merge strategy.

## Nested References

Datum.InvokeCommand automatically resolves nested embedded references. If the result of an embedded command itself contains another embedded command pattern, it is recursively evaluated:

```yaml
# If $Datum.Global.Template returns '[x={ Get-Date }=]',
# the inner command is automatically resolved
Value: '[x={ $Datum.Global.Template }=]'
```

## Configuration

### Customizing Delimiters

The header and footer delimiters are configured in [source/Config/Datum.InvokeCommand.Config.psd1](source/Config/Datum.InvokeCommand.Config.psd1):

```powershell
@{
    Header = '[x='
    Footer = '=]'
}
```

Change these values to use different delimiters, for example:

```powershell
@{
    Header = '[Command='
    Footer = ']'
}
```

### Error Handling

The module respects the `DatumHandlersThrowOnError` property in the Datum definition:

```yaml
# In Datum.yml
DatumHandlersThrowOnError: true
```

| Setting | Behavior |
|---------|----------|
| `$false` (default) | Errors emit warnings and return the original input value. |
| `$true` | Errors are terminating and stop processing immediately. |

## Exported Functions

### Invoke-InvokeCommandAction

The primary action handler. Evaluates embedded commands within Datum configuration data.

```powershell
Invoke-InvokeCommandAction
    -InputObject <Object>
    [-Datum <Hashtable>]
    [-Node <Object>]
    [-ProjectPath <String>]
```

### Test-InvokeCommandFilter

The filter function that determines whether a value contains an embedded command.

```powershell
Test-InvokeCommandFilter
    [-InputObject <Object>]
    [-ReturnValue]
```

For detailed parameter documentation, use `Get-Help`:

```powershell
Get-Help Invoke-InvokeCommandAction -Full
Get-Help Test-InvokeCommandFilter -Full
```

## Complete Example

Below is a complete example of a DSC configuration data project structure using Datum.InvokeCommand.

### Datum.yml

```yaml
ResolutionPrecedence:
  - AllNodes\$($Node.Environment)\$($Node.NodeName)
  - '[x= "Environment\$($Node.Environment)" =]'
  - Locations\$($Node.Location)
  - '[x={ $Node.Role | ForEach-Object { "Roles\$_" } } =]'
  - Baselines\Security
  - Baselines\$($Node.Baseline)
  - Baselines\DscLcm

DatumHandlers:
  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true

default_lookup_options: MostSpecific

lookup_options:
  Configurations:
    merge_basetype_array: Unique
```

### AllNodes/Dev/DSCFile01.yml

```yaml
NodeName: '[x={ $Node.Name }=]'
Environment: '[x={ $File.Directory.Name }=]'
Role: FileServer
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: Frankfurt
Baseline: Server
IpNumber: 100

NetworkIpConfiguration:
  Interfaces:
    - InterfaceAlias: Ethernet
      IpAddress: '[x= "$($Datum.Global.Network.IP.Subnet1).$($Node.IpNumber)" =]'
      Prefix: 24
      Gateway: '[x= "$($Datum.Global.Network.IP.Subnet1).50" =]'
      DnsServer:
        - '[x= "$($Datum.Global.Network.IP.Subnet1).10" =]'
      DisableNetbios: true

DscTagging:
  Layers:
    - '[x={ Get-DatumSourceFile -Path $File }=]'
```

### Multi-Role Node (AllNodes/Dev/DSCFileWeb01.yml)

```yaml
NodeName: '[x={ $Node.Name }=]'
Environment: '[x={ $File.Directory.Name }=]'
Role:
  - FileServer
  - WebServer
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: Frankfurt
```

When Datum resolves this node, the `ResolutionPrecedence` script block `'[x={ $Node.Role | ForEach-Object { "Roles\$_" } } =]'` expands to both `Roles\FileServer` and `Roles\WebServer`, merging configuration from both role definitions.

### Resolving Configuration

```powershell
Import-Module datum
Import-Module Datum.InvokeCommand

# Load the Datum structure
$datum = New-DatumStructure -DefinitionFile .\DscConfigData\Datum.yml

# Get all nodes
$allNodes = Get-DatumNodesRecursive -Nodes $datum.AllNodes -Depth 4

# Compute RSOP for a specific node
$rsop = Get-DatumRsop -Datum $datum -AllNodes $allNodes -Filter { $_.Name -eq 'DSCFile01' }

# Access resolved values
$rsop.NodeName          # 'DSCFile01'
$rsop.Description       # 'FileServer in Dev'
$rsop.NetworkIpConfiguration.Interfaces[0].IpAddress  # e.g., '192.168.1.100'
```

## Relationship to Datum

This module is a **handler module** for the [Datum](https://github.com/gaelcolas/datum/) framework. Datum is a configuration management module for PowerShell DSC that provides a hierarchical data store with merge capabilities similar to Hiera in Puppet.

**Key Datum concepts relevant to this module:**

- **[Datum Handlers](https://github.com/gaelcolas/datum/)**: Extensible modules that process specific patterns in configuration values. Each handler provides a `Test-*Filter` function and an `Invoke-*Action` function.
- **ResolutionPrecedence**: The ordered list of paths Datum searches to resolve a value, supporting hierarchical overrides.
- **RSOP (Resultant Set of Policy)**: The fully merged configuration for a node, computed by walking the `ResolutionPrecedence` list and merging values.
- **Merge Strategies**: Datum supports various merge strategies (`MostSpecific`, `deep`, `Unique`, etc.) that control how values from different levels are combined.

For the complete Datum documentation, visit [https://github.com/gaelcolas/datum/](https://github.com/gaelcolas/datum/).

## Related Projects

- [Datum](https://github.com/gaelcolas/datum/) - The main Datum framework for hierarchical configuration data
- [Datum.ProtectedData](https://github.com/gaelcolas/Datum.ProtectedData) - Datum handler for encrypting/decrypting secrets
- [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) - Full DSC CI/CD pipeline example using Datum

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

For test information, see the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
