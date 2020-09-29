#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

$startTime = Get-Date
$expiryTime = $startTime.AddMinutes(30)
$StorageAccountRG = "aib-devops-rg"
$StorageAccountName = "azminlandevops"
$RootContainer = "templates"
$folder = "arm-templates"

$MainTemplate = "new-workspace.json"

$TargetResourceGroup = $Env:WORKSPACERESOURCEGROUPNAME
$Location = $Env:LOCATION
$SubscriptionId = $Env:SUBSCRIPTIONID
$HostPoolName=$Env:HOSTPOOLNAME
$workspaceName=$Env:WORKSPACENAME

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
    -workspaceName $workspaceName