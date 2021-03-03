function Test-InvokeCommandFilter
{
    <#
    .SYNOPSIS
    Filter function to verify if it's worth triggering the action for the data block.

    .DESCRIPTION
    This function is run in the ConvertTo-Datum function of the Datum module on every pass,
    and when it returns true, the action of the handler is called.

    .PARAMETER InputObject
    Object to test to decide whether to trigger the action or not

    .EXAMPLE
    $object | Test-ProtectedDatumFilter

    #>
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]
        $InputObject,

        [Parameter()]
        [switch]
        $ReturnValue
    )

    if ($InputObject -is [string])
    {
        $all = $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['0'].Value
        $content = $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['Content'].Value

        if ($ReturnValue -and $content)
        {
            $all
        }
        elseif ($content)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        return $false
    }
}
