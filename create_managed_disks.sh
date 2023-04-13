#!/bin/bash

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

resource_group=${resource_group:-"we-my-rg"}
disks_per_node=${disks_per_node:-2}
disk_name_pattern=${disk_name_pattern:-"aks_disk-${aks_name}"}
disk_create_opts1="--zone 1 --sku Premium_LRS --size-gb 1024"

# Get the node resource group
node_resource_group=`az aks show --name $aks_name --resource-group $resource_group --query nodeResourceGroup | tr -d '"'`
echo "node_resource_group:$node_resource_group"


disk_create_opts="--resource-group $node_resource_group $disk_create_opts1 "

# Get vmss name from the resource group
vmss_name=`az vmss list -g $node_resource_group -o yaml  | grep name | head -1 | cut -d: -f 2 | xargs`
echo "vmss_name: $vmss_name"

echo "Switching to $aks_name context"
az aks get-credentials --resource-group $resource_group --name $aks_name
node_cnt=`kubectl get no | grep -v NAME | wc -l`
disks_cnt=$(( disks_per_node * node_cnt ))
echo "node_count=$node_cnt, disks_count=$disks_cnt"

echo "-------Creating $disks_cnt disks--------"
for ((i=0; i<$disks_cnt; i++)); do
    disk_name=${disk_name_pattern}_${i}
    echo "Creating disk: $disk_name"
    az disk create --name $disk_name $disk_create_opts
done

## List the disks  
echo "-------Listing Disks--------"
az disk list -g $node_resource_group -o table  
