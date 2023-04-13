#!/bin/bash

# Start/Stop the Azure resources (hard coded in the variables below)
# Resources are charged on hourly basis (depending upon your subscription)
# starting/stopping the resources help save costs.
# 

opt=$1
if [[ $opt != "start" && $opt != "stop" ]]; then
    echo "Usage: $0 {start|stop}}"
    exit 
fi

# Add your resources in the following variables 
resource_group=${resource_group:-"we-my-rg"}
# TODO: Create list and run in for loop
aks_name1="my_aks"
aks_name2="bmk-aks-pk"
windows_vm="windows-Host"
linux_vm="my-Vm"
linux_vm2="bmk-Vm1"

if [ $opt == "stop" ]; then
    # Stop Resources
    echo "Stopping resources"
    echo "Stopping $aks_name1"
    az aks stop -n $aks_name1 -g $resource_group || true
    echo "Stopping $windows_vm"
    az vm stop -g $resource_group -n $windows_vm 
    echo "Stopping $linux_vm"
    az vm stop -g $resource_group -n $linux_vm 
    echo "Stopping $aks_name2"
    az aks stop -n $aks_name2 -g $resource_group || true
    echo "Stopping $linux_vm2"
    az vm stop -g $resource_group -n $linux_vm2
else
    # Start Resources
    echo "Starting resources"
    echo "Starting $linux_vm"
    az vm start -g $resource_group -n $linux_vm
    echo "Starting $aks_name1"
    az aks start -n $aks_name1 -g $resource_group
    echo "Starting $windows_vm"
    az vm start -g $resource_group -n $windows_vm  
    echo "Starting $aks_name2"
    az aks start -n $aks_name2 -g $resource_group
    echo "Starting $linux_vm2"
    az vm start -g $resource_group -n $linux_vm2
fi 
