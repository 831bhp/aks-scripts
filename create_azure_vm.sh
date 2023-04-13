#!/bin/bash

# This script creates a Ubuntu VM in a provided virtual network

resource_group=${resource_group:-"we-my-rg"}
location="westeurope"
vmName="my-VM"
vnetName="myVNet"
subnetName="myVNet-subnet1"
vmImage="UbuntuLTS"
vmSize="Standard_D2s_v3"
zone="1"

az vm create --resource-group $resource_group --name $vmName --image $vmImage --vnet-name $vnetName --subnet $subnetName --generate-ssh-keys --output json --size $vmSize --zone $zone --location $location --verbose