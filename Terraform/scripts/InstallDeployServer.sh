#!/bin/bash
while getopts u:t:p:a: option
do
case "${option}"
in
u) DEVOPSURL=${OPTARG};;
t) PATTOKEN=${OPTARG};;
p) AGENTPOOL=${OPTARG};;
a) AGENTNAME=${OPTARG};;
esac
done

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update

apt-cache policy docker-ce

sudo apt-get install -y docker-ce

sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
sudo apt-get install -y unzip

cd /home/adminuser
mkdir myagent
wget --quiet https://vstsagentpackage.azureedge.net/agent/2.166.2/vsts-agent-linux-x64-2.166.2.tar.gz
sudo chown adminuser: ~/myagent
sudo chmod o+r+w myagent/
cd myagent

curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli

sudo tar zxvf ../vsts-agent-linux-x64-2.166.2.tar.gz
echo "Install Deps"
sudo bash ./bin/installdependencies.sh > dep.txt
echo "Configure"
sudo runuser -l adminuser -c 'sudo chmod o+x+r+w ~/myagent'

CONFIGCOMMAND="~/myagent/config.sh --unattended --acceptteeeula --url $DEVOPSURL --auth PAT --token $PATTOKEN --pool $AGENTPOOL --agent $AGENTNAME --replace"
echo $CONFIGCOMMAND
runuser -l adminuser -c "$CONFIGCOMMAND"
echo "Run as service"
sudo ./svc.sh install
sudo ./svc.sh start
echo "Script complete"
exit 0