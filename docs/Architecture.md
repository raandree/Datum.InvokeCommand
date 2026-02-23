# Datum.InvokeCommand - Architecture Guide

This document describes the internal architecture, processing pipeline, and design decisions of the Datum.InvokeCommand module.

## Architecture Overview

Datum.InvokeCommand follows the **Datum handler pattern**: a convention where handler modules expose exactly two public functions:

1. **`Test-InvokeCommandFilter`** - A filter function that determines whether a value should be processed by this handler.
2. **`Invoke-InvokeCommandAction`** - An action function that processes the value and returns the result.

The [Datum](https://github.com/gaelcolas/datum/) framework calls these functions automatically during value resolution. The naming convention `Test-<HandlerName>Filter` and `Invoke-<HandlerName>Action` is how Datum discovers and invokes handlers.

## Processing Pipeline

```
                                    Datum Framework
                                         |
                                         v
                             +---------------------------+
                             |   ConvertTo-Datum          |
                             |   (iterates over values)   |
                             +---------------------------+
                                         |
                             For each value in the data:
                                         |
                                         v
                             +---------------------------+
                             |  Test-InvokeCommandFilter  |
                             |  Does value match [x=...=] |
                             |  pattern?                  |
                             +---------------------------+
                                    |            |
                                  Yes           No
                                    |            |
                                    v            v
                             +-----------+   (skip, return
                             |  Invoke-  |    value as-is)
                             |  Invoke-  |
                             |  Command  |
                             |  Action   |
                             +-----------+
                                    |
                                    v
                             +---------------------------+
                             |  Extract content via regex |
                             |  (between header & footer) |
                             +---------------------------+
                                    |
                                    v
                             +---------------------------+
                             |  Get-ValueKind             |
                             |  Parse with PS Parser      |
                             |  Determine: ScriptBlock,   |
                             |  ExpandableString, or      |
                             |  LiteralString             |
                             +---------------------------+
                                    |
                                    v
                             +---------------------------+
                             |  Invoke-InvokeCommand-     |
                             |  ActionInternal            |
                             |  Execute the command       |
                             +---------------------------+
                                    |
                                    v
                             +---------------------------+
                             |  Check for nested          |
                             |  embedded commands         |
                             |  (recursive resolution)    |
                             +---------------------------+
                                    |
                                    v
                              Return result
```

## Module Components

### Public Functions

#### Test-InvokeCommandFilter

- **Purpose**: Determines whether a Datum value contains an embedded command.
- **Called by**: Datum's `ConvertTo-Datum` function on every value.
- **Logic**: Tests if the input is a string matching the compiled regex pattern.
- **Returns**: `$true`/`$false` (or the matched string when `-ReturnValue` is used).
- **File**: [source/Public/Test-InvokeCommandFilter.ps1](../source/Public/Test-InvokeCommandFilter.ps1)

#### Invoke-InvokeCommandAction

- **Purpose**: Evaluates the embedded command and returns the computed value.
- **Called by**: Datum framework when `Test-InvokeCommandFilter` returns `$true`.
- **Logic**:
  1. Extracts content using the regex.
  2. Determines value kind via `Get-ValueKind`.
  3. Resolves `$Node` context if needed via `Get-DatumCurrentNode`.
  4. Delegates execution to `Invoke-InvokeCommandActionInternal`.
  5. Attaches `__File` metadata to results.
- **File**: [source/Public/Invoke-InvokeCommandAction.ps1](../source/Public/Invoke-InvokeCommandAction.ps1)

### Private Functions

#### Get-ValueKind

- **Purpose**: Uses the PowerShell AST parser to classify extracted content.
- **Returns**: Hashtable with `Kind` and `Value` keys.
- **Classification**:
  - `ScriptBlock`: Content wrapped in `{ }` (LCurly/RCurly tokens).
  - `ExpandableString`: Content is a double-quoted string with a `StringExpandable` token.
  - `LiteralString`: Content is a single-quoted string with a `StringLiteral` token.
- **File**: [source/Private/Get-ValueKind.ps1](../source/Private/Get-ValueKind.ps1)

#### Invoke-InvokeCommandActionInternal

- **Purpose**: Executes the parsed command based on its kind.
- **Behavior by kind**:
  - `ScriptBlock`: Creates and invokes via `[scriptblock]::Create()` + `& (& $command)`
  - `ExpandableString`: Expands via `$ExecutionContext.InvokeCommand.ExpandString()`
  - Other: Returns the value as-is.
- **Features**:
  - Self-referencing loop detection (prevents infinite `Get-DatumRsop` recursion).
  - Recursive nested command resolution.
  - Invocation timing/logging.
- **File**: [source/Private/Invoke-InvokeCommandActionInternal.ps1](../source/Private/Invoke-InvokeCommandActionInternal.ps1)

#### Get-DatumCurrentNode

- **Purpose**: Resolves the current node context from a YAML file.
- **Used when**: `Invoke-InvokeCommandAction` is called without an explicit `-Node` parameter.
- **File**: [source/Private/Get-DatumCurrentNode.ps1](../source/Private/Get-DatumCurrentNode.ps1)

#### Get-RelativeNodeFileName

- **Purpose**: Converts absolute file paths to relative Datum node paths.
- **File**: [source/Private/Get-RelativeNodeFileName.ps1](../source/Private/Get-RelativeNodeFileName.ps1)

### Module Initialization (Prefix.ps1)

The [source/Prefix.ps1](../source/Prefix.ps1) file runs at module import time and:

1. Imports the `DscResource.Common` helper module.
2. Loads localized string data for error messages.
3. Reads the handler configuration (header/footer delimiters) from `Config/Datum.InvokeCommand.Config.psd1`.
4. Compiles a regular expression from the delimiters and stores it in `$global:datumInvokeCommandRegEx` for use by the filter and action functions.

### Configuration

The `Config/Datum.InvokeCommand.Config.psd1` file defines:

```powershell
@{
    Header = '[x='
    Footer = '=]'
}
```

These values are escaped and used to build the regex pattern: `[x=(?<Content>((.|\s)+)?)=]`

The `Content` named group captures everything between the header and footer.

## Error Handling Strategy

The module implements a dual-mode error handling strategy controlled by the `DatumHandlersThrowOnError` property in the Datum definition:

### Non-Throwing Mode (Default)

- Invalid regex matches: Warning emitted, original value returned.
- Parse errors (`Get-ValueKind`): Error emitted via `Write-Error`, original value returned.
- Script block execution errors: Warning emitted, original value returned.
- **Rationale**: Allows partial resolution of configuration data; failed values retain their original form for debugging.

### Throwing Mode (`DatumHandlersThrowOnError = $true`)

- Invalid regex matches: Terminating error via `Write-Error -ErrorAction Stop`.
- Parse errors: Propagated as terminating errors.
- Script block execution errors: Terminating error with full context.
- **Rationale**: Ensures data integrity by failing fast on any handler error.

## Global Variables

The module uses the following global variables for cross-scope communication:

| Variable | Purpose |
|----------|---------|
| `$global:datumInvokeCommandRegEx` | Compiled regex for matching embedded commands |
| `$global:CurrentDatumNode` | Current node context during command execution |
| `$global:CurrentDatumFile` | Current file being processed during command execution |

## Relationship to Datum Framework

```
+-------------------+     +-------------------------+     +------------------------+
|  Datum Framework   | --> | Datum.InvokeCommand     | --> | PowerShell Engine      |
|  (datum module)    |     | (this module)            |     | (script execution)     |
+-------------------+     +-------------------------+     +------------------------+
        |                           |
        v                           v
+-------------------+     +-------------------------+
| New-DatumStructure|     | Datum.ProtectedData     |
| Get-DatumRsop     |     | (encryption handler)    |
| ConvertTo-Datum   |     +-------------------------+
+-------------------+
```

For the Datum framework source and documentation, visit [https://github.com/gaelcolas/datum/](https://github.com/gaelcolas/datum/).