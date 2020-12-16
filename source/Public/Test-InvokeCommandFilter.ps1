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
        $InputObject
    )

    $InputObject -is [string] -and $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['Content'].Value
}
