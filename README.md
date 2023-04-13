This repo consist of the scripts that were written in order to setup OpenEBS on Azure Kubernetes Service.
The scripts were created to be run on Ubuntu VM.
There might be some limitations or runtime errors in the scripts and you are welcome to fix them, or, please create an issue and I will try fix it.

Some other commands which I could not put in the script are added in folllowing READMEs:
setup_openebs_buildenv.md
aks_commands.md
push_images_to_acr.md

The repo has following scripts:
1. create_azure_vm.sh
   Creates Azure Ubuntu VM, this is required to access the AKS 
2. create_aks_cluster.sh
   Creates AKS cluster
3. create_managed_disks.sh
   Creates Azure managed disks
4. aks_attach_managed_disks.sh
   Attach the managed disks on the AKS cluster nodes
5. create_lvm_vols.sh
   Create LVM volumes in a stripped configuration
6. run_all.sh
   Run all above scripts in a sequence
7. restore_aks_disks.sh
   Restore/re-attach the disks on the AKS cluster nodes after reboot
8. teardown_lvm.sh
   Remove LVM configuration
9. detach_managed_disks.sh
   Detach the disks from the AKS cluster nodes 
10. delete_aks_cluster.sh
    Delete the AKS cluster
11. teardown.sh
    Teardown all the AKS environment
12. azure_start_stop_resources.sh
    Start/stop the Azure resources

Please contact pritam.bhavsar@gmail.com for any questions/queries/suggestions.