$here = $PSScriptRoot
$modulePath = Join-Path -Path $here -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

# Load the handler configuration (header/footer delimiters) and compile the regular expression
# used to match embedded commands in Datum values. The regex captures the content between the
# configurable header (default: [x=) and footer (default: =]) delimiters.
$config = Import-PowerShellDataFile -Path $here\Config\Datum.InvokeCommand.Config.psd1
$regExString = '{0}(?<Content>((.|\s)+)?){1}' -f [regex]::Escape($config.Header), [regex]::Escape($config.Footer)
$global:datumInvokeCommandRegEx = New-Object Text.RegularExpressions.Regex($regExString, ('IgnoreCase', 'Compiled'))
