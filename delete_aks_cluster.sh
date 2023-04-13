#!/bin/bash
resource_group=${resource_group:-"we-my-rg"}

if [[ ! -z "$1" ]]; then
    aks_name=$1
else
    echo "Error: Please provide the AKS name"
    echo "Usage: $0 {aks name}"
    exit 1
fi

set -euo pipefail 
 
az aks delete -y -g $resource_group -n $aks_name 
