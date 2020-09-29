#!/bin/bash

# Create the image template
az resource create \
    --verbose \
    --resource-group ${IMAGERESORUCEGROUP} \
    --properties @${IMAGETEMPLATEFILENAME} \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n ${IMAGERESOURCENAME}