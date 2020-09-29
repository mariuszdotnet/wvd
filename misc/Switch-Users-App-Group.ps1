param (
    [string]$VaultName,
    [string]$VaultResourceGroupName,
    [string]$SubscriptionId,
    [string]$ActiveHostResourceGroupName
)

$ErrorView = "NormalView"

#Load up the WVD PS module: 
Install-Module -Name Az.DesktopVirtualization -Force -AllowClobber

#Get the active/production host pool from the POD's Key Vault.
$HostsecretName = "active-host-pool"
$WKSsecretName = "wks"
$RoleDefinitionName = "Desktop Virtualization User"
$RoleDefinitionID = "1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63"

$ActiveHostPoolName = (Get-AzKeyVaultSecret -vaultName $VaultName -name $HostsecretName).SecretValueText
$WorkspaceName = (Get-AzKeyVaultSecret -vaultName $VaultName -name $WKSsecretName).SecretValueText

if (!$ActiveHostPoolName) {
    throw "No secret populated. Ensure the right Key Vault is passed"
}
#Assuming the RGP pattern for the Host Pool = build a string and check for existance. 
#Static value for now.

#$ActiveHostResourceGroupName = 'RGP-' + $ActiveHostPoolName

#Set the Resource Group for WVD resources same as vault. 
$WVDRG = $VaultResourceGroupName

# Get Active Application group. Extract the user assignment
$ActiveHostPool = Get-AzWvdHostPool -Name $ActiveHostPoolName -ResourceGroupName $ActiveHostResourceGroupName
[string]$ActiveAppGroupID = $ActiveHostPool.ApplicationGroupReference
Write-Host 'Active App Group ID: '$ActiveAppGroupID

#Determine the target App Group assignment 
$AppGroupIDs = (Get-AzWvdWorkspace -Name $WorkspaceName -ResourceGroupName $WVDRG).ApplicationGroupReference

foreach ($AppGroupID in $AppGroupIDs) {

    if ($AppGroupID -notmatch $ActiveAppGroupID) {
        $TargetAppGroupID = $AppGroupID
        Write-Host 'Target App Group ID: ' $TargetAppGroupID
    }
}

$ActiveUsers = Get-AzRoleAssignment -Scope $ActiveAppGroupID -RoleDefinitionId $RoleDefinitionID
$ActiveUsersObjectIDs = $ActiveUsers.ObjectId
Write-Host 'Active Users that moving to new pool: ' $ActiveUsers

if (!$ActiveUsers) {
    Write-Host "No users assigned to the application group"
}

#Get the user assginment from the Target App Group
$TargetUsers = Get-AzRoleAssignment -Scope $TargetAppGroupID -RoleDefinitionId $RoleDefinitionID
$TargetUsersObjectIDs = $TargetUsers.ObjectId

#Remove the user assigment from the Active App Group and Add to TargetAppGroup
foreach ($ActiveUsersObjectID in $ActiveUsersObjectIDs) {
    Write-Host 'Removing the assignment from' $ActiveAppGroupID ' for object:' $ActiveUsersObjectID
    Remove-AzRoleAssignment -Scope $ActiveAppGroupID -ObjectId $ActiveUsersObjectID -RoleDefinitionId $RoleDefinitionID
    Write-Host 'Adding the users ' $ActiveUsersObjectID 'to target App group' $TargetAppGroupID
    New-AzRoleAssignment -Scope $TargetAppGroupID -ObjectId $ActiveUsersObjectID -RoleDefinitionId $RoleDefinitionID
}

#Get Target Users reassigned to Active App group
foreach ($TargetUsersObjectID in $TargetUsersObjectIDs) {
    Write-Host 'Removing the assignment from' $TargetAppGroupID ' for object:' $TargetUsersObjectID
    Remove-AzRoleAssignment -Scope $TargetAppGroupID -ObjectId $TargetUsersObjectID -RoleDefinitionId $RoleDefinitionID
    Write-Host 'Adding the users ' $TargetUsersObjectID 'to target App group' $ActiveAppGroupID
    New-AzRoleAssignment -Scope $ActiveAppGroupID -ObjectId $TargetUsersObjectID -RoleDefinitionId $RoleDefinitionID
}

Write-Host 'Rotation of users completed'

#Update the Key Vault with new Active Host Pool/Active Group value
Write-Host 'Updating Key Vault ' $VaultName 'with new active Host Pool Value'
$TargetAppGroupName = $TargetAppGroupID.Split('/')[($TargetAppGroupID.Split('/')).count - 1]

[string]$TargetHostPoolId = (Get-AzWvdApplicationGroup -Name $TargetAppGroupName -ResourceGroupName $WVDRG).HostPoolArmPath
$TargetHostPoolName = $TargetHostPoolID.Split('/')[($TargetHostPoolID.Split('/')).count - 1]
$TargetHostPoolNameSecretValue = ConvertTo-SecureString $TargetHostPoolName -AsPlainText -Force
$RotationTime = (Get-Date).ToUniversalTime()
$Tags = @{'RotatedOn' = $RotationTime }
$newHostsecret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $HostsecretName -SecretValue $TargetHostPoolNameSecretValue -Tags $Tags

Write-Host 'Rotated the value of the secret. New active Host Pool is: ' $TargetHostPoolName