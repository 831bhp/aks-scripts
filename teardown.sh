#!/bin/bash
# Teardown the AKS setup

resource_group=${resource_group:-"we-my-rg"}

if [[ ! -z "$1" ]]; then
    aks_name=$1
else
    echo "Error: Please provide the AKS name"
    echo "Usage: $0 {aks name}"
    exit 1
fi

set -euo pipefail

echo "------- Tearing down LVM configutaion --------"
bash ./teardown_lvm.sh $aks_name

echo "------- Detaching and deleting the managed disks --------"
delete_disks=true bash ./detach_managed_disks.sh $aks_name

echo "------- Deleting the AKS cluster: $aks_name --------"
bash ./delete_aks_cluster.sh $aks_name

echo "------- Stopping Jump VMs --------"
bash ./start_stop_resources.sh stop
