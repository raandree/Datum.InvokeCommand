# Datum.InvokeCommand - Getting Started Guide

This guide walks you through setting up and using Datum.InvokeCommand to dynamically compute DSC configuration data.

## Prerequisites

Before you begin, ensure you have the following installed:

- **PowerShell 5.1** or **PowerShell 7+**
- **[Datum](https://github.com/gaelcolas/datum/)** module

```powershell
Install-Module -Name datum
Install-Module -Name Datum.InvokeCommand
```

## What is Datum.InvokeCommand?

[Datum](https://github.com/gaelcolas/datum/) is a PowerShell module that provides hierarchical configuration data with merge capabilities for PowerShell DSC. Think of it as PowerShell's answer to Puppet's Hiera.

**Datum.InvokeCommand** is a *handler module* for Datum. Handlers are plugins that intercept values during resolution and transform them. When Datum encounters a value matching the handler's pattern (e.g., `[x={ Get-Date }=]`), it calls the handler to evaluate the embedded command and returns the result.

## Step 1: Set Up Your Configuration Data

Create a configuration data folder structure:

```plaintext
DscConfigData/
  Datum.yml              # Datum configuration
  Global/
    Network.yml           # Global network settings
    Adds.yml              # Active Directory settings
  Roles/
    FileServer.yml        # File server role configuration
    WebServer.yml         # Web server role configuration
  Environment/
    Dev.yml               # Development environment defaults
    Prod.yml              # Production environment defaults
  AllNodes/
    Dev/
      DSCFile01.yml       # Individual node configuration
      DSCWeb01.yml
    Prod/
      DSCFile02.yml
```

## Step 2: Configure Datum.yml

Register the handler in your `Datum.yml`:

```yaml
ResolutionPrecedence:
  - AllNodes\$($Node.Environment)\$($Node.NodeName)
  - Environment\$($Node.Environment)
  - Locations\$($Node.Location)
  - Roles\$($Node.Role)

DatumHandlers:
  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true
```

## Step 3: Define Global Configuration

Create `Global/Network.yml`:

```yaml
IP:
  Subnet1: 192.168.1
  Subnet2: 10.0.0
```

Create `Global/Adds.yml`:

```yaml
DomainName: contoso
DomainFqdn: contoso.com
DomainDn: DC=contoso,DC=com
```

## Step 4: Use Embedded Commands in Node Files

Create `AllNodes/Dev/DSCFile01.yml`:

```yaml
NodeName: '[x={ $Node.Name }=]'
Environment: '[x={ $File.Directory.Name }=]'
Role: FileServer
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: Frankfurt

NetworkIpConfiguration:
  Interfaces:
    - InterfaceAlias: Ethernet
      IpAddress: '[x= "$($Datum.Global.Network.IP.Subnet1).100" =]'
      Prefix: 24
      Gateway: '[x= "$($Datum.Global.Network.IP.Subnet1).1" =]'
      DnsServer:
        - '[x= "$($Datum.Global.Network.IP.Subnet1).10" =]'
```

**What happens during resolution:**

- `[x={ $Node.Name }=]` resolves to `DSCFile01` (derived from the filename)
- `[x={ $File.Directory.Name }=]` resolves to `Dev` (the parent directory name)
- `[x= "$($Node.Role) in $($Node.Environment)" =]` resolves to `FileServer in Dev`
- `[x= "$($Datum.Global.Network.IP.Subnet1).100" =]` resolves to `192.168.1.100`

## Step 5: Resolve the Configuration

```powershell
Import-Module datum
Import-Module Datum.InvokeCommand

# Load Datum structure
$datum = New-DatumStructure -DefinitionFile .\DscConfigData\Datum.yml

# Get all nodes
$allNodes = @(Get-DatumNodesRecursive -Nodes $datum.AllNodes -Depth 4)

# Compute RSOP for a node
$rsop = Get-DatumRsop -Datum $datum -AllNodes $allNodes `
    -Filter { $_.Name -eq 'DSCFile01' }

# View resolved values
$rsop.NodeName            # 'DSCFile01'
$rsop.Environment         # 'Dev'
$rsop.Description         # 'FileServer in Dev'
$rsop.NetworkIpConfiguration.Interfaces[0].IpAddress  # '192.168.1.100'
```

## Common Patterns

### Referencing the Datum Hierarchy

```yaml
DomainName: '[x={ $Datum.Global.Adds.DomainFqdn }=]'
```

### Computing Values from Node Context

```yaml
Description: '[x= "$($Node.Role) server in $($Node.Environment)" =]'
```

### Getting Current File Information

```yaml
DscTagging:
  Layers:
    - '[x={ Get-DatumSourceFile -Path $File }=]'
```

### Multi-Role Support

```yaml
# In Datum.yml ResolutionPrecedence
- '[x={ $Node.Role | ForEach-Object { "Roles\$_" } } =]'
```

### Complex Queries

```yaml
Computers: '[x={ Get-DatumNodesRecursive -Nodes $Datum.AllNodes -Depth 4 |
    Where-Object { $_.Name -like "*Web*" } |
    ForEach-Object { @{ ComputerName = $_.Name } } }=]'
```

## Next Steps

- Read the [Architecture Guide](Architecture.md) for a deeper understanding
- Read the [Troubleshooting Guide](Troubleshooting.md) for common issues
- Explore the [Datum documentation](https://github.com/gaelcolas/datum/) for the full framework overview
- Look at the [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) for a complete CI/CD pipeline example