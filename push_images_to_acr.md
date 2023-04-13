# Commands to push locally built OpenEBS components to Azure Container Registry
This assumes that -  
   You have already built the OpenEBS's NDM images locally on your system.  
   You have already created/setup AZure Container Registry within your scope.  

## Login to your docker registry  
docker login  

# Login to your Azure ACR  
az login --scope https://management.core.windows.net//.default  
az acr login --name myacr1  

## List your ACR url  
az acr list --resource-group my_resource_group --query "[].{acrLoginServer:loginServer}" --output table  

## List docker images  
docker images  

## Tag the image you want to push to Azure ACR (prefix the ACR URL got in output of the previous command)  
docker tag openebs/node-disk-exporter-amd64:0.7.23024 bmkacr1.azurecr.io/openebs/node-disk-exporter-amd64:0.7.23024  

## List the images  
docker images  

## Push the tagged image  
docker push bmkacr1.azurecr.io/openebs/node-disk-exporter-amd64:0.7.23024  

## List ACR repository  
az acr repository list -n bmkacr1 -o table  

## Repeat the same for other OpenEBS NDM Components (NDO and NDM)  

docker tag openebs/node-disk-operator-amd64:0.7.23024 bmkacr1.azurecr.io/openebs/node-disk-operator-amd64:0.7.23024  
docker push bmkacr1.azurecr.io/openebs/node-disk-operator-amd64:0.7.23024  
docker tag openebs/node-disk-manager-amd64:0.7.23024 bmkacr1.azurecr.io/openebs/node-disk-manager-amd64:0.7.23024  
docker push bmkacr1.azurecr.io/openebs/node-disk-manager-amd64:0.7.23024  

## Purge all Unused or Dangling Images, Containers, Volumes, and Networks  
docker system prune  
docker system prune -a  
docker images -a  
docker rmi Image <Image>  
docker images -f dangling=true  
docker image prune  
docker rmi $(docker images -a -q)  
docker ps -a -f status=exited  
docker stop $(docker ps -a -q)  
docker rm $(docker ps -a -q)  

docker ps -q  
