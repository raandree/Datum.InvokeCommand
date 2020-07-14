function Invoke-InvokeCommandAction
{
    <#
    .SYNOPSIS
    Call the scriptblock that is given via Datum.

    .DESCRIPTION
    When Datum uses this handler to invoke whatever script block is given to it. The returned
    data is used as configuration data.

    .PARAMETER InputObject
    Script block to invoke

    .PARAMETER Header
    Header of the Datum data string that encapsulates the script block.
    The default is [Command= but can be customized (i.e. in the Datum.yml configuration file)

    .PARAMETER Footer
    Footer of the Datum data string that encapsulates the encrypted data. The default is ]

    .EXAMPLE
    $command | Invoke-ProtectedDatumAction

    .NOTES
    The arguments you can set in the Datum.yml is directly related to the arguments of this function.

    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String]
        $Header = '[Command=',

        [Parameter(ValueFromPipelineByPropertyName)]
        [String]
        $Footer = ']'
    )
    
    $command = $InputObject -replace "^$([regex]::Escape($Header))" -replace "$([regex]::Escape($Footer))$"
    try
    {
        $command = [scriptblock]::Create($command)
    }
    catch
    {
        Write-Error -Message ($script:localizedData.CannotCreateScriptBlock -f $inputScript)
    }
    
    Invoke-Command -ScriptBlock $command

}
