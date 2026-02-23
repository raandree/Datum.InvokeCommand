function Invoke-InvokeCommandAction
{
    <#
    .SYNOPSIS
    Invokes a Datum handler action that evaluates embedded commands within Datum configuration data.

    .DESCRIPTION
    This function is the primary action handler for the Datum.InvokeCommand module. It is called by
    the Datum framework when `Test-InvokeCommandFilter` returns `$true` for a given value. The function
    processes input objects that contain embedded commands wrapped in the configurable header/footer
    delimiters (default: `[x=` and `=]`).

    The function supports three types of embedded content:
    - **ScriptBlocks**: Code wrapped in curly braces, e.g., `[x={ Get-Date }=]`
    - **Expandable strings**: Double-quoted strings with variable expansion, e.g., `[x="$($Node.Name)"=]`
    - **Literal strings**: Single-quoted strings (returned as-is with a warning), e.g., `[x='literal'=]`

    When a Datum value contains an embedded command, the handler extracts the content using the configured
    regular expression, determines whether it is a script block or expandable string via `Get-ValueKind`,
    and then invokes or expands it accordingly via `Invoke-InvokeCommandActionInternal`.

    The function provides access to `$Node`, `$Datum`, and `$File` variables within the embedded commands,
    enabling dynamic lookups across the Datum hierarchy.

    Error handling behavior is controlled by the `DatumHandlersThrowOnError` property in the Datum
    definition. When set to `$true`, errors terminate execution; otherwise, warnings are emitted and
    the original input value is returned.

    For more information about Datum and Datum handlers, see https://github.com/gaelcolas/datum/.

    .PARAMETER InputObject
    The input object containing the embedded command string(s) to evaluate. This parameter
    accepts pipeline input. The value should contain a string wrapped with the configured
    header and footer delimiters (default: `[x=` ... `=]`).

    .PARAMETER Datum
    The Datum structure (hashtable) providing access to the full configuration data hierarchy.
    This is made available as `$Datum` within embedded script blocks and expandable strings,
    enabling lookups like `$Datum.Global.Adds.DomainName`.

    .PARAMETER Node
    The current node context (hashtable or object) being processed. If not provided, the function
    attempts to resolve the node from the file path using `Get-DatumCurrentNode`. This is made
    available as `$Node` within embedded commands.

    .PARAMETER ProjectPath
    The root path of the DSC configuration project. Used to resolve relative paths within
    embedded commands.

    .EXAMPLE
    $value = '[x={ Get-Date }=]'
    Invoke-InvokeCommandAction -InputObject $value

    Evaluates the embedded script block `{ Get-Date }` and returns the current date/time.

    .EXAMPLE
    $value = '[x="$($Node.Name) in $($Node.Environment)"=]'
    Invoke-InvokeCommandAction -InputObject $value -Datum $datum -Node $node

    Expands the embedded string using the `$Node` variable, returning something like
    'DSCFile01 in Dev'.

    .EXAMPLE
    $value = '[x={ $Datum.Global.Adds.DomainFqdn }=]'
    Invoke-InvokeCommandAction -InputObject $value -Datum $datum

    Evaluates the script block to return the domain FQDN from Datum's global configuration,
    e.g., 'contoso.com'.

    .EXAMPLE
    $value = '[x={ @{ Name = "Server1"; Value = "Config1" } }=]'
    Invoke-InvokeCommandAction -InputObject $value

    Returns a hashtable from the evaluated script block. Script blocks can return any
    PowerShell object type including hashtables, arrays, and custom objects.

    .EXAMPLE
    '[x={ Get-Date }=]' | Invoke-InvokeCommandAction

    Demonstrates pipeline input support.

    .NOTES
    This function is registered as a Datum handler in the `Datum.yml` configuration file under
    the `DatumHandlers` section:

        DatumHandlers:
          Datum.InvokeCommand::InvokeCommand:
            SkipDuringLoad: true

    The `SkipDuringLoad: true` flag prevents the handler from being invoked during the initial
    Datum structure loading. Commands are evaluated only during value resolution (e.g., RSOP
    computation).

    The header and footer delimiters can be customized in the module configuration file
    `Config\Datum.InvokeCommand.Config.psd1`.

    .LINK
    https://github.com/raandree/Datum.InvokeCommand

    .LINK
    https://github.com/gaelcolas/datum/

    .LINK
    Test-InvokeCommandFilter
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $InputObject,

        [Parameter()]
        [hashtable]
        $Datum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object]
        $Node,

        [Parameter()]
        [string]
        $ProjectPath

    )

    $throwOnError = [bool]$datum.__Definition.DatumHandlersThrowOnError

    if ($InputObject -is [array])
    {
        $returnValue = @()
    }
    else
    {
        $returnValue = $null
    }

    foreach ($value in $InputObject)
    {
        $regexResult = ($datumInvokeCommandRegEx.Match($value).Groups['Content'].Value)
        if (-not $regexResult -and $throwOnError)
        {
            Write-Error "Could not get the content for the Datum.InvokeCommand handler, RegEx '$($datumInvokeCommandRegEx.ToString())' did not succeed." -ErrorAction Stop
        }
        elseif (-not $regexResult -and -not $throwOnError)
        {
            Write-Warning "Could not get the content for the Datum.InvokeCommand handler, RegEx '$($datumInvokeCommandRegEx.ToString())' did not succeed."
            $returnValue += $value
            continue
        }

        $datumType = Get-ValueKind -InputObject $regexResult -ErrorAction (& { if ($throwOnError)
                {
                    'Stop'
                }
                else
                {
                    'Continue'
                } })

        if ($datumType)
        {
            try
            {
                $file = $null

                # avoid TerminatingError in log if $value is an attribute of node.yml
                # -> in this case $value.__File is $null
                if( $value.__File )
                {
                    $file = Get-Item -Path $value.__File -ErrorAction Ignore
                }
            }
            catch
            {
                Write-Verbose 'Invoke-InvokeCommandAction: Nothing to catch'
            }

            if (-not $Node -and $file)
            {
                if ($file.Name -ne 'Datum.yml')
                {
                    $Node = Get-DatumCurrentNode -File $file

                    if (-not $Node)
                    {
                        return $value
                    }
                }
            }

            try
            {
                $returnValue += (Invoke-InvokeCommandActionInternal -DatumType $datumType -Datum $Datum -ErrorAction Stop).ForEach({
                        $_ | Add-Member -Name __File -MemberType NoteProperty -Value "$file" -PassThru -Force
                    })

            }
            catch
            {
                $throwOnError = [bool]$datum.__Definition.DatumHandlersThrowOnError

                if ($throwOnError)
                {
                    Write-Error -Message "Error using Datum Handler $Handler, the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)." -Exception $_.Exception -ErrorAction Stop
                }
                else
                {
                    Write-Warning "Error using Datum Handler $Handler, the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)."
                    $returnValue += $value
                    continue
                }
            }
        }
        else
        {
            $returnValue += $value
        }
    }

    if ($InputObject -is [array])
    {
        , $returnValue
    }
    else
    {
        $returnValue
    }
}
