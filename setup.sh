#!/bin/bash

# Set up randomized names for a storage account and two functions, which must be globally unique
export STORAGE_ACCOUNT_NAME=storestorage$(openssl rand -hex 5)
export PRODUCT_FUNCTION_NAME=ProductFunction$(openssl rand -hex 5)
export ORDER_FUNCTION_NAME=OrderFunction$(openssl rand -hex 5)

# Get the resource group and location
export RESOURCE_GROUP=$(az group list --query "[0].name" -o tsv)
export LOCATION=$(az group show --name $RESOURCE_GROUP | jq -r ".location")
printf "\nThe resource group is called $RESOURCE_GROUP and is located in $LOCATION\n"

# Create a storage account
printf "\nCreating a storage account for the functions...\n"
az storage account create --name $STORAGE_ACCOUNT_NAME --location $LOCATION --resource-group $RESOURCE_GROUP  --sku Standard_LRS
printf "\nStorage account created.\n"

# Create two functions in Azure
printf "\nCreating function apps in Azure...\n"
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION --name $PRODUCT_FUNCTION_NAME --storage-account $STORAGE_ACCOUNT_NAME --runtime dotnet --functions-version 2
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION --name $ORDER_FUNCTION_NAME --storage-account $STORAGE_ACCOUNT_NAME --runtime dotnet --functions-version 2
printf "\nFunction apps created.\n"

# Building the zip files for the functions
printf "\nBuilding zip files for deployment...\n"
for zipFile in ProductDetailsFunc OrderShippingFunc
do
    mkdir $zipFile
    unzip -q $zipFile.zip -d $zipFile
    cd $zipFile/bin/Debug/netcoreapp2.1
    zip -q -r ~/OnlineStoreFuncs/$zipFile.PKG.zip ./*
    cd ~/OnlineStoreFuncs/
done
printf "\nZip files built.\n"

# Use zip deploy to publish the code
printf "\nPublishing function source code...\n"
az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $PRODUCT_FUNCTION_NAME --src ProductDetailsFunc.PKG.zip
az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $ORDER_FUNCTION_NAME --src OrderShippingFunc.PKG.zip
printf "\nCode published. Functions are ready to use.\n"
