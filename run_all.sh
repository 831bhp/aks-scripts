#!/bin/bash

# Provision all: 
#  Create AKS Cluster
#  Create managed disks
#  Attach managed disks
#  Create LVM configuration
#  Install OpenEBS helm chart

resource_group=${resource_group:-"we-my-rg"}
acr_name=${acr_name:-"myacr1"}

# Currently only 2 disks per node are supported by the scripts
disks_per_node=${disks_per_node:-2}
disk_name_pattern=${disk_name_pattern:-"aks_disk"}

# LVM configuration
vg_name=${vg_name:-"openebs-vg"}
lv_name=${lv_name:-"openebs-lv"}
openebs_mountpath=${openebs_mountpath, "/var/openebs/local"}

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

echo "------- Creating AKS Cluster --------"
resource_group=$resource_group bash ./create_aks_cluster.sh $aks_name

echo "------- Creating managed disks --------"
resource_group=$resource_group disks_per_node=$disks_per_node disk_name_pattern=$disk_name_pattern bash ./create_managed_disks.sh $aks_name

echo "------- Attaching managed disks --------"
resource_group=$resource_group disks_per_node=$disks_per_node disk_name_pattern=$disk_name_pattern bash ./attach_managed_disks.sh $aks_name

echo "------- Creating LVM configuration --------"
resource_group=$resource_group disks_per_node=$disks_per_node vg_name=$vg_name lv_name=$lv_name openebs_mountpath=$openebs_mountpath bash ./create_lvm_vols.sh $aks_name

if [[ !`command -v helm`  > /dev/null ]];then
    echo "Installing Helm"
    bash ../fio_tests/get_helm.sh
fi

echo "-------- Installing OpenEBS helm chart --------"
sudo helm repo update
sudo helm repo add openebs https://openebs.github.io/charts
sudo helm install openebs --namespace openebs openebs/openebs --create-namespace

echo "-------- Listing Storage classes ---------"
kubectl get sc

echo "--------- Listing OpenEBS pods ---------"
kubectl get pods -n openebs

#echo "--------- Attaching the ACR myacr1 to AKS $aks_name ---------"  
#az aks update -n $aks_name -g $resource_group --attach-acr $acr_name

sleep 10
echo "--------- Listing pods ---------"
kubectl get pods -A

echo "Run 'kubectl get pods' to check the status of the pods"
echo "-------All done-------"
