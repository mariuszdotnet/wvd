#!/bin/bash
expiretime=$(date -u -d '30 minutes' +%Y-%m-%dT%H:%MZ)
storageAccountRG="Azureminilab-Lighthouse"
storageAccountName="azminlandevops"
rootcontainer="templates"
container="arm-templates"

connection=$(az storage account show-connection-string \
  --resource-group $storageAccountRG \
  --name $storageAccountName \
  --query connectionString)
token=$(az storage container generate-sas \
  --name $rootcontainer \
  --expiry $expiretime \
  --permissions r \
  --output tsv \
  --connection-string $connection)

  url=$(az storage blob url \
   --container-name $rootcontainer/$container \
   --name main-template.json \
   --output tsv \
   --connection-string $connection)

  url1=$(az storage blob url \
   --container-name $rootcontainer/$container \
   --name azmin-params.json \
   --output tsv \
   --connection-string $connection)

 parameter='{"_artifactsLocationSasToken":{"value":"?'$token'"}}'
 az deployment group create --resource-group ${SESSIONHOSTRESOURCEGROUPNAME} --template-uri $url?$token --parameters $url1?$token  --parameters $parameter
