#### Install go
wget https://go.dev/dl/go1.19.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

sudo apt update
sudo apt install build-essential
sudo apt update
sudo apt install build-essential
gcc --version
make install-dep

#### Install Docker
sudo apt install gnome-terminal
sudo apt-get update certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings/download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 

echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo docker run hello-world

## Fix docker permission issue
sudo usermod -aG docker $USER && newgrp docker
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "/home/$USER/.docker" -R

### Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb

sudo dpkg -i minikube_latest_amd64.deb
## Start minikube and mount /run/udev in minikube container at /run/udev
minikube start --driver=docker --mount-string="/run/udev/:/run/udev" --mount

#### Create OpenEBS build environment
## Use node-disk-manager component

git clone https://github.com/openebs/node-disk-manager.git
# Update Makefile to change the BASEIMAGE to FF base image
# Update tag from “ci” to “ci-pb” (Optional)
make
docker images # check if the nds images are listed

## Update integration_tests/yamls/node-disk-manager.yaml file
# Update image - `image: openebs/node-disk-manager-amd64:ci`
# Set imagePullPolicy: Never

## Upload the images to minikube docker daemon
minikube image load openebs/node-disk-exporter-amd64:ci-pb
minikube image load openebs/node-disk-operator-amd64:ci-pb
minikube image load openebs/node-disk-manager-amd64:ci-pb

## Check minikube docker registry
eval $(minikube docker-env)
docker images   # This will switch docker context to minikube docker env.

## Run integration test
make integration-tests

#### Delete minikube env
minikube stop --all
minikube delete --all