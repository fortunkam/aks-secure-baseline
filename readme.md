# Private Azure Kubernetes Cluster with DevOps Build Agents

This repo shows how to provision an environment for working with a private AKS cluster.
It includes.
- A Private Link Enabled AKS cluster with outbound traffic routed to a firewall (so no public IP addresses owned by the cluster)
- An Azure Firewall to control the outbound traffic
- 2 virtual networks peered to simulate a hub/spoke model of resource placement
- A Private Link Enabled Container Registry (ACR) - Note: this is currently in preview!
- A Windows VM configured as a Jump off box/bastion machine for remote access to the network
- An Ubuntu Linux machine configured as an Azure DevOps build agent with Docker Installed.
- An Ubuntu Linux machine configured as an Azure DevOps deploy agent with Kubernetes CLI installed.

## Pre-requisites

You will need the following installed to deploy this (versions I used show in brackets)
- Azure CLI (v2.3.0)
- Terraform (v0.12.24)
- Powershell Core (v7.0.0)
- An Azure Subscription
- An Azure DevOps Account (and the ability to generate Service Connections/Pipelines/Manage Build Agents)

## Setting up DevOps

In your Azure DevOps account you will need to create 2 new Build agent pools (Project Settings - Agent Pools)
![Agent Pools](/images/DevOps%20Build%20Agent.png "Agent Pools")

You will also need to create a Personal Access Token (PAT) so that the build agents can be registered with your DevOps account
![PAT Token Menu](/images/PAT%20TOken%20Menu.png "PAT Token Menu")
![New PAT Token](/images/PAT%20TOken%20-%20New%20Token.png "New PAT Token")
I have create my token with access to everything, in a real world scenario you will need to decide the minimum permissions required.

## Getting ready to run Terraform

In the Terraform folder create a file called terraform.tfvars, this will contain the variables you pass to create your environment.
The file should contain the following...

    location = "<THE AZURE LOCATION TO DEPLOY YOUR RESOURCES>"
    prefix = "<A 5 CHARACTER PREFIC THAT WILL MAKE YOUR DEPLOYMENT UNIQUE>"
    devopsUrl = "https://dev.azure.com/<YOUR DEVOPS ORG>"
    devopsPatToken = "<YOUR PAT TOKEN>"
    devopsBuildAgentPool = "<YOUR BUILD AGENT POOL NAME>"
    devopsDeployAgentPool = "<YOUR DEPLOY AGENT POOL NAME>"

for example

    location = "centralus"
    refix = "mfaks"
    evopsUrl = "https://dev.azure.com/myOrg"
    evopsPatToken = "thisrandomcollectionofcharactersismypattoken"
    evopsBuildAgentPool = "SelfHostLinuxBuildAgents"
    devopsDeployAgentPool = "SelfHostLinuxDeployAgents"

Save this file and open up a powershell window.
navigate to the Terraform folder.
Log in to you azure account using 

    az login
Select the correct subscription using

    az account list
and then 

    az account set --subscription "<SUBSCRIPTION NAME OR ID>"

Now Initialize Terraform

    terraform init

and finally run with (note the auto-approve flag skips the manual verification step)

    terraform apply -auto-approve

This will take about 20 minutes to provision everything.
When it is complete you should have 1 build agent configured and active per group in azure DevOps.
![Configured DevOps Agent](/images/DevOpsConfiguredAgent.png "Configured DevOps Agent")

## Configuring Azure Devops to work with your new AKS cluster

Before we can deploy to our new AKS cluster we need to create a service account that DevOps will use to authenticate.  A Service Account template has been provided [here](/AKS/DeployServiceAccount.yaml).

In order to run this template you will need to be within the private network we created.  A Jump off/Bastion machine has been provisioned for this purpose.  In a real world scenario you may want to consider a VPN connection from your on-prem network to the azure network for simplicity.
The username is `AzureAdmin
The password can be found either in the KeyVault (located in the Hub Resource Group) or by running the following command.

    terraform output

The password for the VM (and the Private SSH key for the build agents) will be displayed in the console.  Use a remote desktop client to connect to the bastion VM (the public IP address for it can be found in the azure portal).

Once on the machine, start Edge (Chromium version has been installed) and set this as the default browser (it makes life easier later).
Now open a powershell window and log into your azure account using

    az login

and set the default subscription using the `az account show` and `az account set` commands as before.

Now connect to the AKS cluster using 

    az aks get-credentials --name <AKS NAME> --resource-group <SPOKE RESOURCE GROUP NAME>

Now copy the [DeployServiceAccount.yaml](/AKS/DeployServiceAccount.yaml) file to the VM and run the following command

    kubectl apply -f <PATH TO DeployServiceAccount.yaml>

Once run you now need to get the service account details for use in Azure DevOps, on the VM run the following to get the AKS private link name.

    kubectl config view --minify -o=jsonpath="{.clusters[0].cluster.server}"

now get the secret used to store the credentials with

    kubectl get serviceAccounts deploy -n kube-system -o=jsonpath="{.secrets[*].name}"

now use the secret name from the previous command (something like deploy-token-12345) to get the json secret using 

    kubectl get secret <secret-name-from-previous-command> -n kube-system -o json > token.json

the json secret will be found in a file called token.json, open this file and select all (this is what you will need to copy to Azure DevOps).

Now back onto your host machine, in Azure DevOps create a new Kubernetes Service Connection.
![Create Service Connection Step 1](/images/CreateServiceConnectionStep1.png "Create Service Connection Step 1")
![Create Service Connection Step 2](/images/CreateServiceConnectionStep2.png "Create Service Connection Step 2")
![Create Service Connection Step 3](/images/CreateServiceConnectionStep3.png "Create Service Connection Step 3")
use the values for the AKS URL and Json Secret in the highlighted fields, give your connection a name and save.  You can now use this connection in any kubectl task in your pipelines.

## Deploy a sample project




## Useful links
[https://docs.microsoft.com/en-us/azure/aks/private-clusters]

[https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks]

[https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html]

[https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal]

[https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link]

[https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml]

Instead of using Linux machines for build agents you could use Docker build agents.

[https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux]
