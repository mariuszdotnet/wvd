#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

$startTime = Get-Date
$expiryTime = $startTime.AddMinutes(30)
$StorageAccountRG = "aib-devops-rg"
$StorageAccountName = "azminlandevops"
$RootContainer = "templates"
$folder = "arm-templates"

$MainTemplate = "main-template-kv2a.json"

$TargetResourceGroup = "Azureminilab-WVD-DEV-BLUE"
$Location = "canadacentral"
$SubscriptionId = "1965c25a-b7fd-48b5-a393-c9e785c1c4d9"
$TargetWorkspaceResourceGroup = "Azureminilab-WVD-Pod2"
$HostPoolName = "SBX-HostPool-DEV-rnr-BLUE"
$VaultName = "SBX-USE2-WVD-DEV-rnr-KV"
$VaultResourceGroupName="Azureminilab-WVD-Pod2"
$subnetid="blue-subnet-id"
$netappshare="netapp-blue"
$desID="/subscriptions/1965c25a-b7fd-48b5-a393-c9e785c1c4d9/resourceGroups/Azureminilab-WVD-DES/providers/Microsoft.Compute/diskEncryptionSets/DEV-disk-encrypt-key"

$rg = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
if (!$rg) {
    $rg = New-AzResourceGroup -Name $TargetResourceGroup -Location $Location
}

Set-AzCurrentStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName

$token = New-AzStorageContainerSASToken -Name $RootContainer -ExpiryTime $expiryTime -Permission "r"

$templateUri = (Get-AzStorageBlob -Blob "$folder/$MainTemplate" -Container $RootContainer).ICloudBlob.Uri.AbsoluteUri

$secureToken = ConvertTo-SecureString -String $token -AsPlainText -Force

New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup `
    -TemplateUri "$templateUri$token" -Verbose `
    -VaultName $VaultName `
    -VaultResourceGroupName $VaultResourceGroupName `
    -VaultSubscriptionId $SubscriptionId `
    -subnetid $subnetid `
    -netappshare $netappshare `
    -desID $desID `
    -host-pool-resource-group $TargetWorkspaceResourceGroup `
    -HostPoolName $HostPoolName `
    -artifactsLocationSasToken $secureToken