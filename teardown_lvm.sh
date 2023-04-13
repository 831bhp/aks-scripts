#!/bin/bash

# Teardown the LVM configuration done on all the nodes.

resource_group=${resource_group:-"we-my-rg"}

if [[ ! -z "$1" ]]; then
    aks_name=$1
else
    echo "Error: Please provide the AKS name"
    echo "Usage: $0 {aks name}"
    exit 1
fi

#------- Update following variables before running the script ---------#
disk_list=("/dev/sdc" "/dev/sdd")
ndisks=2
vg_name="openebs-vg"
lv_name="openebs-lv"
openebs_mountpath="/var/openebs/local"

# TODO: Remove hardcoding
disk1=aks-pdisk1
disk2=aks-pdisk2
disk3=aks-pdisk3
disk4=aks-pdisk4
disk5=aks-pdisk5
disk6=aks-pdisk6

# Get the node resource group
node_resource_group=`az aks show --name $aks_name --resource-group $resource_group --query nodeResourceGroup | tr -d '"'`
echo "node_resource_group:$node_resource_group"

# Get vmss name from the resource group
vmss_name=`az vmss list -g $node_resource_group -o yaml  | grep name | head -1 | cut -d: -f 2 | xargs`
echo "vmss_name: $vmss_name"

set -euo pipefail

# Get VMSS instance Ids from following command
echo "Switching to $aks_name context"
az aks get-credentials --resource-group $resource_group --name $aks_name
node_cnt=`kubectl get no | grep -v NAME | wc -l`
echo "node_cnt=$node_cnt"
# az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table
node_ids=`az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table | tail -n $node_cnt | awk '{print $1}'`
echo "node_ids=$node_ids"

cat > /tmp/remove_lvm.sh << EOF
vg_name="openebs-vg"
lv_name="openebs-lv"
openebs_mountpath="/var/openebs/local"
sudo umount \$openebs_mountpath
sudo lvremove -y /dev/\$vg_name/\$lv_name
sudo vgremove -y \$vg_name
sudo pvremove -y ${disk_list[@]}
sudo wipefs -a -f ${disk_list[0]}
sudo wipefs -a -f ${disk_list[1]}
EOF

for i in $node_ids; do
    az vmss run-command invoke  --command-id RunShellScript --name $vmss_name -g $node_resource_group --scripts @/tmp/remove_lvm.sh --instance-id $i || true
done

rm -f /tmp/remove_lvm.sh
