#!/bin/bash

# This script assumes that the AKS cluster is already created
# Creates and attaches two disks on all the nodes in the AKS cluster
# The script may not work if there are multiple node pools in the cluster.

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
disk_name_pattern=${disk_name_pattern:-"aks_disk-${aks_name}"}
disks_per_node=${disks_per_node:-2}
disk_sku="Premium_LRS"

# Get the node resource group
node_resource_group=`az aks show --name $aks_name --resource-group $resource_group --query nodeResourceGroup | tr -d '"'`
echo "node_resource_group:$node_resource_group"

# Get vmss name from the resource group
vmss_name=`az vmss list -g $node_resource_group -o yaml  | grep name | head -1 | cut -d: -f 2 | xargs`
echo "vmss_name: $vmss_name"

echo "Switching to $aks_name context"
az aks get-credentials --resource-group $resource_group --name $aks_name
node_cnt=`kubectl get no | grep -v NAME | wc -l`
echo "node_cnt=$node_cnt"
node_ids=`az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table | tail -n $node_cnt | awk '{print $1}'`
echo "node_ids=$node_ids"

i=0
for id in $node_ids; do
    for ((d=0; d<$disks_per_node; d++)); do
        disk_name="${disk_name_pattern}_${i}"
        echo "Attaching disk $disk_name to node id $id"
        az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk_name --sku $disk_sku --instance-id $id
        i=$((i+1))
    done
done
