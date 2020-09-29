#!/bin/bash

expiretime=$(date -u -d '30 minutes' +%Y-%m-%dT%H:%MZ)
storageAccountRG="Azureminilab-Lighthouse"
storageAccountName="azminlandevops"
currentpath=$(pwd)
connection=$(az storage account show-connection-string \
  --resource-group $storageAccountRG \
  --name $storageAccountName \
  --query connectionString)
token=$(az storage container generate-sas \
  --name templates \
  --expiry $expiretime \
  --permissions rw \
  --output tsv \
  --connection-string $connection)

# upload contents to storage account 
az storage blob upload-batch --account-name $storageAccountName -d "templates" --sas-token $token -s $currentpath


# url=$(az storage blob url \
#   --container-name templates \
#   --name parent.json \
#   --output tsv \
#   --connection-string $connection)
# parameter='{"containerSasToken":{"value":"?'$token'"}}'
# az deployment group create --resource-group ExampleGroup --template-uri $url?$token --parameters $parameter