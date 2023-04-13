#!/bin/bash

# Script to provision a private AKS cluster within a existing virtual network 

# This script assumes that the following things are already created:
#   1. Service Principal (replace service_principal and client_secret variables with apt values)
#   2. Virtual Network
#   3. Subnet in a virtual network

resource_group=${resource_group:-"we-my-rg"}

location="westeurope"
service_principal="mySP"
vnetName="myVNet"
vnet_subnet_resource_id="/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXX4b9fe6/resourceGroups/we-my-rg/providers/Microsoft.Network/virtualNetworks/my-VNet/subnets/myVNet-subnet1"
subnetName="subnet1"
vnetAddressPrefix="172.0.0.0/16"  
subnetAddressPrefix="172.0.0.0/22"  
service_principal="8aa63463-da74-40f9-b4e1-1aa0b0484212"
client_secret="16581368-cdfc-45f2-b762-662467da540e"
#Intel CPU
vm_size=Standard_E16ads_v5
#ARM CPU
#vm_size=Standard_E16ps_v5
node_count=3
nodepool_name="e16psv5"


if [[ ! -z "$1" ]]; then
    if [[ "$1" = "-h" ]]; then
        echo "Usage: $0 {aks name}"
        exit 0
    fi
    aks_name=$1
else
    echo "Error: Please provide the AKS name"
    echo "Usage: $0 {aks name}"
    exit 1
fi

set -euo pipefail 
az aks create -g $resource_group -n $aks_name --node-count $node_count --zones 1 --location $location --service-principal $service_principal --client-secret $client_secret --vnet-subnet-id $vnet_subnet_resource_id --node-vm-size $vm_size --nodepool-name $nodepool_name --ssh-key-value ~/.ssh/id_rsa.pub --enable-private-cluster  --load-balancer-sku standard --network-plugin azure 

