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

cd /home/adminuser
mkdir myagent
wget --quiet https://vstsagentpackage.azureedge.net/agent/2.166.2/vsts-agent-linux-x64-2.166.2.tar.gz
sudo chown adminuser: ~/myagent
sudo chmod o+r+w myagent/
cd myagent

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