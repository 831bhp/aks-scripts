#!/bin/bash

# This script creates LVM configuration on all the AKS nodes to be used by OpenEBS local PV
# Assumptions:
#   1. AKS cluster is already created
#   2. the disks are already attached to the nodes

#--------- Update these variables ---------------
resource_group=${resource_group:-"we-my-rg"}
vg_name=${vg_name:-"openebs-vg"}
lv_name=${lv_name:-"openebs-lv"}
openebs_mountpath=${openebs_mountpath:-"/var/openebs/local"}
instance_wo_tempdisk="Standard_E16ps_v5"

# How many disks are to be attached per node (minimum 2).
# For 3 node in AKS cluster:
# 1. If there are 6 disks then use 2 disks per node.
# 2. If there are 12 disks then use 4 disks per node.
disks_per_node=${disks_per_node:-2}

kubectl cluster-info dump | grep  "node.kubernetes.io/instance-type" | grep $instance_wo_tempdisk 2>&1 >> /dev/null
# For Standard_E16ps_v5 VM type the external disk name starts with /dev/sdb
if [ $? -eq 0 ]
then
    # Create list of the attached disks on VM, 
    # External disks start with /dev/sdb
    case $disks_per_node in
        2)
        disk_list="/dev/sdb /dev/sdc"
        ;;
        3)
        disk_list="/dev/sdb /dev/sdc /dev/sdd"
        ;;
        4)
        disk_list="/dev/sdb /dev/sdc /dev/sdd /dev/sde"
        ;;
        5)
        disk_list="/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf"
        ;;
        6)
        disk_list="/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg"
        ;;
        *)
        echo "Only following number of disks are supported: 2, 3, 4, 5, 6."
        exit 1
        ;;
    esac
else
    # List: name of the attached disks on VM
    # External disks start with /dev/sdc
    case $disks_per_node in
        2)
        disk_list="/dev/sdc /dev/sdd"
        ;;
        3)
        disk_list="/dev/sdc /dev/sdd /dev/sde"
        ;;
        4)
        disk_list="/dev/sdc /dev/sdd /dev/sde /dev/sdf"
        ;;
        5)
        disk_list="/dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg"
        ;;
        6)
        disk_list="/dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh"
        ;;
        *)
        echo "Only following number of disks are supported: 2, 3, 4, 5, 6."
        exit 1
        ;;
    esac
fi

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

# Get disk Ids
node_ids=`az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table | tail -n $node_cnt | awk '{print $1}'`
echo "node_ids=$node_ids"

for id in $node_ids; do
    echo "Creating LVM configuration on vmss instance id $id"
    cat > /tmp/create_lvm.sh << EOF
pvcreate  $disk_list
vgcreate  $vg_name $disk_list
lvcreate -l 50%VG -i $disks_per_node -I 512 -n $lv_name $vg_name
#lvcreate -l 50%VG -i $disks_per_node -n $lv_name $vg_name
mkfs.xfs /dev/$vg_name/$lv_name
mkdir -p $openebs_mountpath
mount  /dev/$vg_name/$lv_name $openebs_mountpath
EOF

    az vmss run-command invoke  --command-id RunShellScript --name $vmss_name -g $node_resource_group --scripts @/tmp/create_lvm.sh --instance-id $id

    echo "Creating network tunables"
    cat > /tmp/tune_network.sh << EOF
sysctl -w vm.swappiness=10
sysctl -w net.core.somaxconn=5000
sysctl -w net.core.rmem_default=262144
sysctl -w net.core.wmem_default=262144
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.core.rmem_default=134217728
sysctl -w net.core.wmem_default=134217728
sysctl -w net.core.optmem_max=40960
sysctl -w net.ipv4.tcp_rmem=134217728
sysctl -w net.ipv4.tcp_wmem=134217728
sysctl -w net.core.netdev_max_backlog=250000
sysctl -w net.ipv4.tcp_max_syn_backlog=3000
sysctl -w fs.file-max=10000
EOF
    az vmss run-command invoke  --command-id RunShellScript --name $vmss_name -g $node_resource_group --scripts @/tmp/tune_network.sh --instance-id $id
done

/bin/cp /tmp/create_lvm.sh /tmp/create_lvm_$$.sh
rm -f /tmp/create_lvm.sh

for id in $node_ids; do
    echo "------Listing the LVM configuration on vmss instance $id-----"
    az vmss run-command invoke  --command-id RunShellScript --name $vmss_name -g $node_resource_group --scripts "lsblk" --instance-id $id
done
