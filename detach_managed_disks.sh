#!/bin/bash

# This script detaches the managed disks attached to the AKS nodes

resource_group=${resource_group:-"we-my-rg"}
delete_disks=${delete_disks:-"false"}

if [[ ! -z "$1" ]]; then
    aks_name=$1
else
    echo "Error: Please provide the AKS name"
    echo "Usage: $0 {aks name}"
    exit 1
fi

set -euo pipefail

disks_per_node=${disks_per_node:-2}
disk_name_pattern=${disk_name_pattern:-"aks_disk-${aks_name}"}
disks=""

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
# az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table
node_ids=`az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table | tail -n $node_cnt | awk '{print $1}'`

disks=""
i=0

for id in $node_ids; do
    for ((d=0; d<$disks_per_node; d++)); do
        if [ "${disks}" = "" ]; then
                disks="${disk_name_pattern}_${i}"
        else
                disks="${disks} ${disk_name_pattern}_${i}"
        fi
        i=$((i+1))
    done
done
echo "Disks formed are : $disks"

#disks=(aks-pdisk1 aks-pdisk2 aks-pdisk3 aks-pdisk4 aks-pdisk5 aks-pdisk6 aks-pdisk7 aks-pdisk8 aks-pdisk9 aks-pdisk10 aks-pdisk11 aks-pdisk12)
#disks=(aks-pdisk1 aks-pdisk2 aks-pdisk3 aks-pdisk4 aks-pdisk5 aks-pdisk6 aks-pdisk7 aks-pdisk8 aks-pdisk9 aks-pdisk10 aks-pdisk11 aks-pdisk12)
#disks_per_node=2


echo "node_ids=$node_ids"
for id in $node_ids; do
    for ((d=0; d<$disks_per_node; d++)); do
        echo "Dettaching LUN$d from VMSS node id $id"
        az vmss disk detach --resource-group $node_resource_group --vmss-name $vmss_name  --instance-id $id --lun $d || true
    done
done

# Delete the disks
echo " Deleting the managed disks"
if [[ $delete_disks = "true" ]]; then
    for d in ${disks[@]}; do
        echo "Deleting: $d"
        az disk delete -y --name $d --resource-group $node_resource_group     
    done
fi
