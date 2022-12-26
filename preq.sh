#!/bin/bash

export AWS_WORKDIR=$HOME/Downloads/aws > /dev/null
export AWS_VER=$(aws --version | awk -F"[/ ]+" '/aws-cli/{print $2}') > /dev/null
export HELM_VER=$(helm version | awk '{ print $1}' | cut -d'"' -f2) > /dev/null
export K8S_VER=$(kubectl version -o yaml 2>/dev/null | awk '{print $2}' | sed -n 6,6p) > /dev/null
export EKSCTL_VER=$(eksctl version) > /dev/null

ORNG="\e[33m"
BLUE="\e[36m"
LBLUE="\e[36m"
YLLW="\e[33m"
END="\e[0m"
GRN="\e[32m"
RED="\e[31m"

spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

install_aws()
{
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --create-dirs -o "$AWS_WORKDIR/awscliv2.zip"
    unzip $AWS_WORKDIR/awscliv2.zip -d $AWS_WORKDIR > /dev/null
    sudo $AWS_WORKDIR/aws/install 2> /dev/null
    echo "export PATH=/usr/local/bin/aws_completer:$PATH" >> $HOME/.bashrc
    echo "complete -C '/usr/local/bin/aws_completer' aws" >> $HOME/.bashrc
}

install_eksctl()
{
### EKSCTL
 
curl --location -O "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar xzf eksctl_$(uname -s)_amd64.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
echo ". <(eksctl completion bash)" >> $HOME/.bashrc
}

install_k8s()
{
### K8S
 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "alias k=kubectl" >> $HOME/.bashrc
echo "complete -o default -F __start_kubectl k" >> $HOME/.bashrc
} 

install_helm()
{
### HELM
 
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "source <(helm completion bash)" >> $HOME/.bashrc
}
 
echo ""
echo "-----------------------------------"
echo " Prerequisits Installation for EKS "
echo "-----------------------------------"
echo ""
echo " ------------------------------------------------"
echo " Checking for required tools (curl, zip, wget)..."
echo " ------------------------------------------------"
echo ""
echo " ---------------"
echo " Updating system"
echo " ---------------"

sudo apt update -y

sleep 2 & spinner

REQUIRED_PKG="curl"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
if [ "" = "$PKG_OK" ];
then
  echo " ---------------------------------------"
  echo " No $REQUIRED_PKG found. Installing up $REQUIRED_PKG."
  echo " ---------------------------------------"
  sudo apt-get -y install $REQUIRED_PKG
else
  echo ""
  echo -e "${GRN} ------------------------------- ${END}"
  echo -e "${GRN} $REQUIRED_PKG already installed! ${END}"
  echo -e "${GRN} ------------------------------- ${END}"
  echo ""
fi

REQUIRED_PKG="zip"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
if [ "" = "$PKG_OK" ];
then
  echo ""
  echo " ------------------------"
  echo " No $REQUIRED_PKG found. Installing up $REQUIRED_PKG."
  echo " ------------------------"
  sudo apt-get -y install $REQUIRED_PKG
else
  echo -e "${GRN} ------------------------- ${END}"
  echo -e "${GRN} $REQUIRED_PKG already installed! ${END}"
  echo -e "${GRN} ------------------------ ${END}"
fi

REQUIRED_PKG="wget"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
if [ "" = "$PKG_OK" ];
then
  echo " ---------------------------"
  echo " No $REQUIRED_PKG found. Installing up $REQUIRED_PKG."
  echo "----------------------------"
  sudo apt-get -y install $REQUIRED_PKG
else
  echo -e "${GRN} ------------------------ ${END}"
  echo -e "${GRN} $REQUIRED_PKG already installed! ${END}"
  echo -e "${GRN} ------------------------ ${END}"
fi

echo -e "${GRN} ------------------ ${END}"
echo -e "${GRN} Packages installed ${END}"
echo -e "${GRN} ------------------ ${END}"
echo ""

########## AWS CLI

echo -e "${ORNG} --------------------------------- ${END}" 
echo -e "${ORNG} Checking for AWS CLI on system... ${END}"
echo -e "${ORNG} --------------------------------- ${END}"

sleep 1 & spinner

if [[ -n $(which aws) ]];
then
  echo -e "${ORNG} -------------------------- ${END}"
  echo -e "${GRN} AWS CLI already installed. ${END}"
  echo -e "${ORNG} Current version - $AWS_VER ${END}"
  echo -e "${ORNG} -------------------------- ${END}"
  echo ""
  echo "------------"
  echo "Moving on..."
  echo "------------"
else
  echo ""
  echo -e "${RED} No AWS CLI found... ${END}"
  echo -e "${ORNG} Installing AWS CLI ${END}"
  install_aws & spinner
  echo ""
  echo -e "${GRN} -------------------------------- ${END}"
  echo -e "${ORNG} AWS CLI${END} ${GRN}Succesfully installed... ${END}"
  echo -e "${GRN} -------------------------------- ${END}"
  echo ""
fi

echo "export PATH=/usr/local/bin/aws_completer:$PATH" >> $HOME/.bashrc
echo "complete -C '/usr/local/bin/aws_completer' aws" >> $HOME/.bashrc

sleep 1

#########  EKSCTL

echo -e "${YLLW} ------------------------------- ${END}"
echo -e "${YLLW} Checking for EksCtl on system... ${END}"
echo -e "${YLLW} ------------------------------- ${END}"

sleep 1 & spinner

if [[ -n $(which eksctl) ]];
then
  echo -e "${YLLW} -------------------------- ${END}"
  echo -e "${GRN} EksCtl already installed. ${END}"
  echo -e "${YLLW} Current version - $EKSCTL_VER ${END}"
  echo -e "${YLLW} -------------------------- ${END}"
  echo ""
  echo "------------"
  echo "Moving on..."
  echo "------------"
else
  echo ""
  echo -e "${RED} No EksCtl found...${END}"
  echo -e "${YLLW} Installing EksCtl CLI ${END}"
  install_eksctl & spinner
  echo ""
  echo -e "${GRN} -------------------------------- ${END}"
  echo -e "${YLLW} EksCtl${END} ${GRN}Succesfully installed... ${END}"
  echo -e "${GRN} -------------------------------- ${END}"
  echo ""
fi

#########  KUBECTL 

echo -e "${BLUE} --------------------------------- ${END}"
echo -e "${BLUE} Checking for KubeCtl on system... ${END}"
echo -e "${BLUE} --------------------------------- ${END}"

sleep 1 & spinner

if [[ -n $(which kubectl) ]];
then
  echo -e "${BLUE} -------------------------- ${END}"
  echo -e "${GRN} KubeCtl already installed. ${END}"
  echo -e "${BLUE} Current version - $K8S_VER ${END}"
  echo -e "${BLUE} -------------------------- ${END}"
  echo ""
  echo "------------"
  echo "Moving on..."
  echo "------------"
else
  echo -e "${RED} No KubeCtl found... ${END}"
  echo -e "${BLUE} Installing KubeCtl CLI ${END}"
  install_k8s & spinner
  echo ""
  echo -e "${GRN} -------------------------------- ${END}"
  echo -e "${BLUE} KubeCtl ${END} ${GRN} Succesfully installed... ${END}"
  echo -e "${GRN} -------------------------------- ${END}"
  echo ""
fi

#########  HELM 

echo -e "${LBLUE} --------------------------------- ${END}"
echo -e "${LBLUE} Checking for Helm on system... ${END}"
echo -e "${LBLUE} --------------------------------- ${END}"

sleep 1 & spinner

if [[ -n $(which helm) ]];
then
  echo -e "${LBLUE} -------------------------- ${END}"
  echo -e "${GRN} HELM already installed. ${END}"
  echo -e "${LBLUE} Current version - $HELM_VER ${END}"
  echo -e "${LBLUE} -------------------------- ${END}"
  echo ""
  echo "------------"
  echo "Moving on..."
  echo "------------"
else
  echo ""
  echo -e "${RED} No HELM found...${END}"
  echo -e "${LBLUE} Installing HELM CLI ${END}"
  install_helm & spinner
  echo ""
  echo -e "${GRN} -------------------------------- ${END}"
  echo -e "${LBLUE} HELM ${END} ${GRN} Succesfully installed... ${END}"
  echo -e "${GRN} -------------------------------- ${END}"
  echo ""
fi

########

echo ""
echo -e "${GRN} ----------------${END}"
echo -e "${GRN}  Tools are ready ${END}"
echo -e "${GRN} ----------------${END}"
echo ""

echo ""
echo -e "${GRN} Installed tools and versions: ${END}"
echo ""
echo -e "${ORNG} AWS CLI ${END} - $AWS_VER"
echo -e "${BLUE} KubeCtl CLI ${END} - $K8S_VER"
echo -e "${YLLW} AWS EksCtl ${END} - $EKSCTL_VER"
echo -e "${LBLUE} HELM CLI ${END} - $HELM_VER"
echo ""
echo "-------------------------------"
echo -e "\e[5;96m     WolkAbout DevOps Crew"
echo ""
echo ""
echo -e "\e[5;160m⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣤⣤⣤⣤⣶⣦⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀${END} "
echo -e "\e[5;161m⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⡿⠛⠉⠙⠛⠛⠛⠛⠻⢿⣿⣷⣤⡀⠀⠀⠀⠀⠀${END} "
echo -e "\e[5;162m⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠋⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⠈⢻⣿⣿⡄⠀⠀⠀⠀${END}"
echo -e "\e[5;163m⠀⠀⠀⠀⠀⠀⠀⣸⣿⡏⠀⠀⠀⣠⣶⣾⣿⣿⣿⠿⠿⠿⢿⣿⣿⣿⣄⠀⠀⠀${END}"
echo -e "\e[5;164m⠀⠀⠀⠀⠀⠀⠀⣿⣿⠁⠀⠀⢰⣿⣿⣯⠁⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣷⡄⠀${END}"
echo -e "\e[5;165m⠀⠀⣀⣤⣴⣶⣶⣿⡟⠀⠀⠀⢸⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⠀${END}"
echo -e "\e[5;166m⠀⢰⣿⡟⠋⠉⣹⣿⡇⠀⠀⠀⠘⣿⣿⣿⣿⣷⣦⣤⣤⣤⣶⣶⣶⣶⣿⣿⣿⠀${END}"
echo -e "\e[5;167m⠀⢸⣿⡇⠀⠀⣿⣿⡇⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀${END}"
echo -e "\e[5;168m⠀⣸⣿⡇⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠉⠻⠿⣿⣿⣿⣿⡿⠿⠿⠛⢻⣿⡇⠀⠀${END}"
echo -e "\e[5;169m⠀⣿⣿⠁⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣧⠀⠀${END}"
echo -e "\e[5;170m⠀⣿⣿⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠀${END}"
echo -e "\e[5;171m⠀⣿⣿⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠀${END}"
echo -e "\e[5;172m⠀⢿⣿⡆⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡇⠀⠀${END}"
echo -e "\e[5;173m⠀⠸⣿⣧⡀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠃⠀⠀${END}"
echo -e "\e[5;174m⠀⠀⠛⢿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⣰⣿⣿⣷⣶⣶⣶⣶⠶⠀⢠⣿⣿⠀⠀⠀${END}"
echo -e "\e[5;175m⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⡇⠀⣽⣿⡏⠁⠀⠀⢸⣿⡇⠀⠀⠀${END}"
echo -e "\e[5;176m⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⡇⠀⢹⣿⡆⠀⠀⠀⣸⣿⠇⠀⠀⠀${END}"
echo -e "\e[5;177m⠀⠀⠀⠀⠀⠀⠀⢿⣿⣦⣄⣀⣠⣴⣿⣿⠁⠀⠈⠻⣿⣿⣿⣿⡿⠏⠀⠀⠀⠀${END}"
echo -e "\e[5;178m⠀⠀⠀⠀⠀⠀⠀⠈⠛⠻⠿⠿⠿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${END}"
echo ""
