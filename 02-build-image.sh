#!/bin/bash

# Start the image build
az resource invoke-action \
     --verbose \
     --resource-group ${IMAGERESORUCEGROUP} \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n ${IMAGERESOURCENAME} \
     --action Run