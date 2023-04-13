# AZ account show/list
az account show --output table

# Querying a single value
az account show --query name 
az account show --query [name,id,user.name] # return multiple values
az account show --query [name,id,user.name] -o table # return multiple values as a table

# Create a resource group
resourceGroup="bmkResourceGroup-1"
location="West Europe"
az group create --name $resourceGroup --location "$location"

# Delete a resource group
az group delete --name $resourceGroup -y

# Clean up all resources
if [ $(az group exists --name $resourceGroup) = true ]; then 
   az group delete --name $resourceGroup -y  --no-wait
else
   echo The $resourceGroup resource group does not exist
fi


# Create a storage account
storageAccount="bmkStorageAccount-1"
az storage account create --name $storageAccount --location "$location"

# returns both storage account key values
az storage account keys list --resource-group $resourceGroup --account-name $storageAccount --query "[].value" -o tsv 



# Create Azure Service Principal
## Note down the credentials
az ad sp create-for-rbac

# List Azure Container Registries
az acr list

# Create AKS (simple command)
az aks create --resource-group we-infra-perf-bm-aks-1_group --name bmkAKS2 --location westeurope --attach-acr benchmarkingACR1 --generate-ssh-keys

#Connect to AKS from Macbook terminal
az aks get-credentials --resource-group we-infra-perf-bm-aks-1_group --name bmkAKS2

# HELM commands

helm repo add openebs https://openebs.github.io/charts
helm repo update
helm install -g --namespace openebs openebs/openebs --create-namespace
# helm upgrade openebs-1649336056 openebs/openebs \
# 	--namespace openebs \
# 	--set legacy.enabled=true \
# 	--reuse-values

# For other engines, you will need to perform a few more additional steps to
# enable the engine, configure the engines (e.g. creating pools) and create 
# StorageClasses. 

# For example, cStor can be enabled using commands like:
<!-- 
helm upgrade openebs-1649336056 openebs/openebs \
	--namespace openebs \
	--set cstor.enabled=true \
	--reuse-values
 -->

helm ls -n openebs
helm delete openebs-1649336056 -n openebs
kubectl get namespace
kubectl delete namespace openebs

# Install OpenEBS local hostapth PV
helm install -g --namespace openebs openebs/openebs --create-namespace
kubectl get pods -n openebs

# The default values will install NDM and enable OpenEBS hostpath and device
# storage engines along with their default StorageClasses. Use `kubectl get sc`
# to see the list of installed OpenEBS StorageClasses.

# **Note**: If you are upgrading from the older helm chart that was using cStor
# and Jiva (non-csi) volumes, you will have to run the following command to include
# the older provisioners:

helm upgrade openebs-1649356619 openebs/openebs \
	--namespace openebs \
	--set legacy.enabled=true \
	--reuse-values

# For other engines, you will need to perform a few more additional steps to
# enable the engine, configure the engines (e.g. creating pools) and create 
# StorageClasses. 

# For example, cStor can be enabled using commands like:

helm upgrade openebs-1649356619 openebs/openebs \
	--namespace openebs \
	--set cstor.enabled=true \
	--reuse-values

kubectl get sc                       
kubectl get pods -n openebs -l openebs.io/component-name=openebs-localpv-provisioner

mkdir bmkAKS2
cd bmkAKS2 
vi local-hostpath-pvc.yaml
kubectl get pvc
kubectl apply -f local-hostpath-pvc.yaml
kubectl get pvc                         
vi local-hostpath-pod.yaml
kubectl apply -f local-hostpath-pod.yaml
kubectl get pod hello-local-hostpath-pod
kubectl get pod hello-local-hostpath-pod
kubectl get pod hello-local-hostpath-pod
kubectl exec hello-local-hostpath-pod -- cat /mnt/store/greet.txt

# Connect to worker node in kubernetes cluster

kubectl get nodes -o wide
kubectl debug node/aks-nodepool1-11541500-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
helm ls -n openebs
kubectl get bd -n openebs
kubectl get pod -n openebs
helm upgrade openebs-1649356619 openebs/openebs  --set cstor.enabled=true --reuse-values --namespace openebs      
kubectl get pods -n openebs

kubectl get pod -n openebs

# Activate ssh exon into vmss
# AKS Resource group name:MC_we-infra-perf-bm-aks-1_group_bmkAKS2_westeurope

# VM Scaliest name: aks-nodepool1-11541500-vmss

az vmss list --resource-group  MC_we-infra-perf-bm-aks-1_group_bmkAKS2_westeurope -o tsv                 

#Connect & install the open-iscsi package on worker node

kubectl get nodes -o wide                                                                                 
kubectl debug node/aks-nodepool1-11541500-vmss000001 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
chroot /host
uname -a
apt update
apt install -y open-iscsi

# Create an Azure disk 
az aks show --resource-group we-infra-perf-bm-aks-1_group --name bmkAKS2 --query nodeResourceGroup -o tsv
az disk create --resource-group MC_we-infra-perf-bm-aks-1_group_bmkAKS2_westeurope --name bmkUSSD1 --sku UltraSSD_LRS --size-gb 5  --query id --output tsv
az disk create --resource-group MC_we-infra-perf-bm-aks-1_group_bmkAKS2_westeurope --name bmkUSSD2 --sku UltraSSD_LRS --size-gb 5  --query id --output tsv
az disk create --resource-group MC_we-infra-perf-bm-aks-1_group_bmkAKS2_westeurope --name bmkUSSD3 --sku UltraSSD_LRS --size-gb 5  --query id --output tsv

#Create Storage class for Ultra SSD
vi ~/Experiments/bmkAKS2/StorageClass-USSD.yml
kubectl apply -f ~/Experiments/bmkAKS2/StorageClass-USSD.yml 

#Create static PV
vi ~/Experiments/bmkAKS2/pv-static-ussd.yml
kubectl apply -f ~/Experiments/bmkAKS2/pv-static-ussd.yml
kubectl get pv  

#Create static PV
vi ~/Experiments/bmkAKS2/pvc-static-ussd.yml
kubectl apply -f ~/Experiments/bmkAKS2/pvc-static-ussd.yml 
kubectl get pvc                                           

# Enable Ultra disks on an existing cluster
az aks nodepool add --name ultradisk --cluster-name bmkAKS2 --resource-group we-infra-perf-bm-aks-1_group --node-vm-size Standard_D2s_v3 --zones 1 2 --node-count 2 --enable-ultra-ssd
az aks create with service principal
az ad sp create-for-rbac -n bmk_aks_sp2 --role contributor \
    --scopes /subscriptions/e054c9f5-d781-4a83-a835-2296004b9fe6/resourceGroups/we-infra-perf-bm-aks-1_group

# az aks create with 3 nodes, 2 zones, location, service principal & accessible over multiple VNET
az aks create -g we-infra-perf-bm-aks-1_group -n bmkAKS4 --node-count 3 --zones {1,2} --location westeurope --service-principal "c29eb76f-549d-4510-97dd-91d6101067e6" --client-secret "x2-e8P~OHlr.5rOxNBO3BcjtPiTeGwnD20" --vnet-subnet-id "/subscriptions/e054c9f5-d781-4a83-a835-2296004b9fe6/resourceGroups/we-infra-perf-bm-aks-1_group/providers/Microsoft.Network/virtualNetworks/bmk-vnet1/subnets/default" --vnet-subnet-id "/subscriptions/e054c9f5-d781-4a83-a835-2296004b9fe6/resourceGroups/we-infra-perf-bm-aks-1_group/providers/Microsoft.Network/virtualNetworks/bmk-vnet1/subnets/bmkaksopen-subnet1"
iscsiadm --mode discovery --op update --type sendtargets --portal 172.24.0.5

# Add remote ssh connection to kubernetes nodes:
#https://trstringer.com/aks-ssh-to-node/
#https://github.com/trstringer/az-aks-ssh


vi /etc/systemd/system/iscsi.service
kubectl rollout restart deployment openebs-ndm-operator -n openebs
kubectl exec --stdin --tty shell-demo -- /bin/bash
kubectl exec hello-local-hostpath-pod -- cat /mnt/store/greet.txt

# Set NSG rule for the resource group
az network nsg list -g we-infra-perf-bm-aks-1_group -o table
az network nsg rule create -g we-infra-perf-bm-aks-1_group --nsg-name bmk-vm1-nsg -n SshRule --priority 100 --source-address-prefixes Internet --destination-port-ranges 22 --access Allow --protocol Tcp --direction Inbound

# Login to Kubernetes node
./az-aks-ssh.sh -g we-infra-perf-bm-aks-1_group -n bmkAKS4 -d aks-nodepool1-30572907-vmss000000

# DISCOVER ISCSI LUNs
iscsiadm --mode discovery --op update --type sendtargets --portal 172.24.0.5
iscsiadm --mode node -l all
iscsiadm --mode session


