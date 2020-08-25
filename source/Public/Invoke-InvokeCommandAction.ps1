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
    Footer of the Datum data string that encapsulates the scriptblock you are running. The default is ]
    
    .PARAMETER YamlFilePath
    Set 'YamlFilePath: $File' in your datum.yml file to allow this script to be aware of the calling source .yml file.
    This allows you to access the other adjacent properties from your node.yml/role.yaml/location.yaml/environment.yaml files via the exposed $yamlObj variable.
    
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
        $Footer = ']',

        [String]
        $YamlFilePath
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
    
    $yamlObj = $null
    if($YamlFilePath -and (test-path $YamlFilePath) ){
        $yamlObj = gc $YamlFilePath | ConvertFrom-Yaml 
    }

    Invoke-Command -ScriptBlock $command

}
