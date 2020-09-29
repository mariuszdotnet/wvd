#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

$startTime = Get-Date
$expiryTime = $startTime.AddMinutes(30)
$StorageAccountRG = "WVD-CACN-Core-Infra"
$StorageAccountName = "azminlandevops01"
$RootContainer = "templates"
$folder = "arm-templates"
$workspaceId = "/subscriptions/45a36c26-54ca-48a8-b3c8-e582d6c8627b/resourcegroups/wvd-cacn-core-infra/providers/microsoft.operationalinsights/workspaces/wvd-la-workspace02"

$MainTemplate = "new-diskencryptset.json"

$TargetResourceGroup = "Azureminilab-WVD-DES"
$Location = "canadacentral"

$rg = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
if (!$rg) {
    $rg = New-AzResourceGroup -Name $TargetResourceGroup -Location $Location
}

Set-AzCurrentStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName

$token = New-AzStorageContainerSASToken -Name $RootContainer -ExpiryTime $expiryTime -Permission "r"

$templateUri = (Get-AzStorageBlob -Blob "$folder/$MainTemplate" -Container $RootContainer).ICloudBlob.Uri.AbsoluteUri

$secureToken = ConvertTo-SecureString -String $token -AsPlainText -Force

<#New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup `
    -TemplateUri "$templateUri$token" -Verbose `
    -artifactsLocationSasToken $secureToken
    #>

New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup `
    -TemplateFile "$folder\$MainTemplate" -Verbose `
    -KeyVaultLocation "canadacentral" `
    -artifactsLocationSasToken $secureToken `
    -_artifactsLocation "https://$StorageAccountName.blob.core.windows.net/" `
    -workspaceId $workspaceId `
    -PersonaName "PR02" `
    -environment "WVD"