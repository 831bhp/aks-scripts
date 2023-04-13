#!/bin/bash

# If the AKS cluster is rebooted the disks attached to the nodes
# need to be re-attached along with the LVM configuration.
# This script does the job, some hardcoding needs to be addressed though.

set -euo pipefail

#------- Update following variables before running the script ---------#
resource_group=${resource_group:-"we-my-rg"}
aks_name=${aks_name:-"myaks"}
node_resource_group="MC_we-my-rg_westeurope"
vmss_name="aks-e16adsv5-NNNNN177-vmss"

# TODO: Remove hardcoding
disk1=aks-pdisk1
disk2=aks-pdisk2
disk3=aks-pdisk3
disk4=aks-pdisk4
disk5=aks-pdisk5
disk6=aks-pdisk6

# Get VMSS instance Ids from following command
# az vmss list-instances --resource-group $node_resource_group --name $vmss_name -o table

# TODO: Remove hardcoding
vmss_node1_id=3
vmss_node2_id=4
vmss_node3_id=5

vg_name="openebs-vg"
lv_name="openebs-lv"
openebs_mountpath="/var/openebs/local"

# Attach disk1 & disk 2 to instance 0 (node 0)
echo "Attaching $disk1 to $vmss_node1_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk1 --sku Premium_LRS --instance-id $vmss_node1_id
echo "Attaching $disk2 to $vmss_node1_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk2 --sku Premium_LRS --instance-id $vmss_node1_id

# Attach disk3 & disk 4 to instance 1 (node 1)
echo "Attaching $disk3 to $vmss_node2_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk3 --sku Premium_LRS --instance-id $vmss_node2_id
echo "Attaching $disk4 to $vmss_node2_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk4 --sku Premium_LRS --instance-id $vmss_node2_id

# Attach disk5 & disk 6 to instance 2 (node 2)
echo "Attaching $disk5 to $vmss_node2_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk5 --sku Premium_LRS --instance-id $vmss_node3_id
echo "Attaching $disk6 to $vmss_node2_id"
az vmss disk attach --resource-group $node_resource_group --vmss-name $vmss_name --disk $disk6 --sku Premium_LRS --instance-id $vmss_node3_id

# Restore the LVM configuration
cat > /tmp/restore_lvm.sh << EOF
vg_name="openebs-vg"
lv_name="openebs-lv"
openebs_mountpath="/var/openebs/local"
mkdir -p /var/openebs/local
mount  /dev/\$vg_name/\$lv_name \$openebs_mountpath
EOF

for i in $vmss_node1_id $vmss_node2_id $vmss_node3_id; do
    az vmss run-command invoke  --command-id RunShellScript --name $vmss_name -g $node_resource_group --scripts @/tmp/restore_lvm.sh --instance-id $i
done

rm -f /tmp/restore_lvm.sh
