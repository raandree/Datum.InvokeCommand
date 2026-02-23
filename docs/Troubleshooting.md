# Datum.InvokeCommand - Troubleshooting Guide

Common issues, error messages, and their solutions when using Datum.InvokeCommand.

## Common Issues

### Handler Not Being Invoked

**Symptom**: Values like `[x={ Get-Date }=]` are returned as plain strings instead of being evaluated.

**Cause**: The handler is not registered in `Datum.yml` or the module is not imported.

**Solution**:

1. Verify the handler is registered in `Datum.yml`:

```yaml
DatumHandlers:
  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true
```

2. Ensure the module is imported before resolving Datum:

```powershell
Import-Module -Name Datum.InvokeCommand
```

3. Confirm the module is available:

```powershell
Get-Module -Name Datum.InvokeCommand -ListAvailable
```

### Regex Match Failure

**Symptom**: Warning message: *"Could not get the content for the Datum.InvokeCommand handler, RegEx '...' did not succeed."*

**Cause**: The header/footer delimiters in the value don't match the configured pattern.

**Solution**:

1. Check the configured delimiters in `Config\Datum.InvokeCommand.Config.psd1`:

```powershell
Import-PowerShellDataFile .\source\Config\Datum.InvokeCommand.Config.psd1
```

Default: Header = `[x=`, Footer = `=]`

2. Ensure your embedded commands use the correct delimiters:

```yaml
# Correct (with default delimiters)
Value: '[x={ Get-Date }=]'

# Incorrect (wrong delimiters)
Value: '[Command={ Get-Date }]'
```

3. Verify the closing delimiter is properly placed. Multi-line values are especially prone to this issue.

### Script Block Parse Errors

**Symptom**: Error message: *"The input object '...' cannot be converted into a ScriptBlock: ..."*

**Cause**: The content between delimiters is not valid PowerShell syntax.

**Solution**:

1. Test the script block independently:

```powershell
$sb = [scriptblock]::Create('Get-Date')
& $sb
```

2. Common syntax issues:
   - Missing closing brace `}`
   - Unbalanced quotes
   - Invalid PowerShell syntax within the script block

3. For multi-line script blocks in YAML, ensure proper formatting:

```yaml
# Correct - YAML block scalar
Value: |
  [x={
    Get-Date
  }=]

# Correct - Inline
Value: '[x={ Get-Date }=]'

# Incorrect - Line break breaks the pattern
Value: '[x={ Get-Date
}=]'
```

### Get-ValueKind Errors

**Symptom**: Error message: *"The input object is not an ExpandableString, nor a literal string or ScriptBlock"*

**Cause**: The content between delimiters is not wrapped in `{ }`, `" "`, or `' '`.

**Solution**:

Ensure the content uses one of the supported formats:

```yaml
# Script block (curly braces)
Value: '[x={ Get-Date }=]'

# Expandable string (double quotes)
Value: '[x= "$($Node.Name)" =]'

# Literal string (single quotes - returned as-is with warning)
Value: "[x='literal'=]"

# Incorrect - no wrapper
Value: '[x= Get-Date =]'
```

### $Node Variable is $null

**Symptom**: Embedded commands referencing `$Node` return empty/null values.

**Cause**: The node context couldn't be resolved automatically.

**Solution**:

1. Ensure the value originates from a node-specific file (under `AllNodes/`), not from `Datum.yml` directly.

2. When calling `Invoke-InvokeCommandAction` directly, pass the `-Node` parameter:

```powershell
Invoke-InvokeCommandAction -InputObject $value -Node $node -Datum $datum
```

3. The `$Node` resolution requires the `$File` metadata property (`__File`) to be set on the input object. This is handled automatically by Datum during RSOP resolution.

### $Datum Variable is $null

**Symptom**: Embedded commands referencing `$Datum` return empty/null values.

**Cause**: The `-Datum` parameter was not passed to the action function.

**Solution**:

When Datum calls the handler automatically (during RSOP resolution), it passes the Datum structure. If you're calling the function directly:

```powershell
Invoke-InvokeCommandAction -InputObject $value -Datum $datum
```

### Self-Referencing Loop

**Symptom**: Infinite loop or stack overflow when using `Get-DatumRsop` within an embedded command.

**Cause**: A script block calls `Get-DatumRsop` which triggers the handler again, creating a recursive loop.

**Solution**: The module includes built-in loop detection. If `Get-DatumRsop` is already in the call stack, the raw value is returned instead of executing it again. If you still experience issues, review your script blocks for circular references.

### YAML Quoting Issues

**Symptom**: YAML parse errors or values not being recognized as handler patterns.

**Cause**: Improper quoting in YAML files.

**Solution**:

Always use **single quotes** around values containing the `[` character, as `[` has special meaning in YAML:

```yaml
# Correct - single outer quotes
Value: '[x={ Get-Date }=]'

# Correct - escaped double-quoted value inside single-quoted YAML
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'

# Incorrect - no quotes (YAML will try to parse [ as a list)
Value: [x={ Get-Date }=]
```

### Error Handling Mode

The module supports two error handling modes controlled by `DatumHandlersThrowOnError` in the Datum definition.

**To enable strict error handling (fail-fast):**

```yaml
# In Datum.yml
DatumHandlersThrowOnError: true
```

Or set it programmatically:

```powershell
$datum.__Definition.DatumHandlersThrowOnError = $true
```

**To use lenient error handling (default):**

Errors emit warnings, and the original value is returned. This allows partial resolution but may mask configuration issues.

## Diagnostic Steps

### Check Module Version

```powershell
Get-Module -Name Datum.InvokeCommand -ListAvailable |
    Select-Object -Property Name, Version, Path
```

### Verify Regex Pattern

```powershell
# Check the compiled regex
$datumInvokeCommandRegEx.ToString()

# Test a value manually
$testValue = '[x={ Get-Date }=]'
$datumInvokeCommandRegEx.Match($testValue).Groups['Content'].Value
```

### Enable Verbose Logging

```powershell
$VerbosePreference = 'Continue'
Invoke-InvokeCommandAction -InputObject '[x={ Get-Date }=]' -Verbose
```

### Test Filter Function

```powershell
# Should return $true
Test-InvokeCommandFilter -InputObject '[x={ Get-Date }=]'

# Should return $false
Test-InvokeCommandFilter -InputObject 'Just a regular string'
```

## Getting Help

- **Module help**: `Get-Help Invoke-InvokeCommandAction -Full`
- **Datum documentation**: [https://github.com/gaelcolas/datum/](https://github.com/gaelcolas/datum/)
- **Issues**: [https://github.com/raandree/Datum.InvokeCommand/issues](https://github.com/raandree/Datum.InvokeCommand/issues)
- **DSC Community**: [https://dsccommunity.org/](https://dsccommunity.org/)