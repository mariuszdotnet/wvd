[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ResourceGroupName = "WVD-CACN-Core-Infra",
    [Parameter()]
    [string]
    $VirtualNetworkName = "WVD-CACN-VNET01",
    # Persona ID
    [Parameter()]
    [string]
    $PersonaId = "PR02",
    # Pod amount
    [Parameter()]
    [hashtable]
    $Pods = @{
        POD01 = "10.100.2.0/25";
        POD02 = "10.100.2.128/25";
        POD03 = "10.100.3.0/25";
        POD04 = "10.100.3.128/25";
    }
)

$az = Get-AzContext

$SubscriptionId = $az.Subscription.Id

Write-Host "Current Subscription ID $SubscriptionId"

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if (!$rg) {
    throw "Resource Group $ResourceGroupName does not exist. Run Setup.ps1 to create."
}

$vnet = $rg | Get-AzVirtualNetwork -Name $VirtualNetworkName -ErrorAction SilentlyContinue

if (!$vnet) {
    throw "Virtual Network $VirtualNetworkName does not exist. Run Setup.ps1 to create."
}

foreach ($podId in $Pods.Keys ) {

    $subnetName = "$PersonaId-$podId"
    Write-Host "Subnet $subnetName"

    $existingSubnet = $vnet.Subnets | Where-Object Name -EQ $subnetName

    if ($existingSubnet) { 
        Write-Host "Exists"
        Continue 
    }
    
    Write-Host "Creating subnet $subnetName - with address $($Pods[$podId])"
    $vnet = $vnet | Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $Pods[$podId] | Set-AzVirtualNetwork

}
