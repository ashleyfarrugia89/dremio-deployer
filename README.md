Dremio Deployment Tool
====

The unofficial script for deploying Dremio in IaaS deployments. This script enables administrators to deploy Dremio securely and efficiently to their cloud subscription. Dremio deployment tool fully deploys the infrastructure (if required) and Dremio to cloud-native Kubernetes. 

The key features of this tool are:

- **Cloud Support**: Only currently supporting Azure, although this might change in due course to include other vendors.
- **Effortless Deployment**: Deploys Dremio to Cloud-native Kubernetes with limited effort required from administrators.
- **Flexible Configuration**: Enables administrators to interact with the script at different stages, depending on their environment setup.

## Pre-requisites

- Azure Subscription with owner privileges
- Azure Enterprise Application
- Azure storage account - this is required for Terraform state backup

## Software requirements
- [Helm](https://helm.sh/)
- [Terraform](https://www.terraform.io/downloads)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Kubernetes or KubeCTL](https://kubernetes.io/docs/tasks/tools/)

## Permissions

> If using Enterprise Application (EA) you will need to assign the required Azure permissions. If you are Owner of the subscription then please skip this step.

- Assign Contributor role
- Create custom role for dremio using create_custom_dremio_role.sh and assign to EA
- Assign Storage Blob Data Owner to EA

## Setup
1. Update dremio.config with relevant values for the following variables: 
| Variable 	| Description 	| Required 	|
|---	|---	|---	|
| DOCKER_USER 	| Docker Username used to access Dremio on Dockerhub 	| Yes 	|
| DOCKER_PASSWD 	| Docker Password used to access Dremio on Dockerhub 	| Yes 	|
| DOCKER_EMAIL 	| Docker Email used to access Dremio on Dockerhub 	| Yes 	|
| DREMIO_TF_DIR 	| Directory where the terraform script is located 	| Yes 	|
| DREMIO_CONF 	| Directory where the Dremio Helm chart is located 	| Yes 	|
| TLS_PRIVATE_KEY_PATH 	| Location of the private key (only required when enabling TLS) 	| No 	|
| TLS_CERT_PATH 	| Location of the TLS cert (only required when enabling TLS) 	| No 	|
| AAD_GROUP_NAME 	|  	|  	|
| AAD_CLIENT_ID 	| Azure Enterprise Application Client ID 	| Yes 	|
| AAD_SECRET 	| Azure Enterprise Application Secret 	| Yes 	|
| AAD_APP_NAME 	| Azure Enterprise Application Name 	| Yes 	|
| AAD_TENANT_ID 	| Azure Tenant for the Enterprise Application 	| Yes 	|
| AZURE_SUB_ID 	| Azure Subscription ID 	| Yes 	|
| DREMIO_DNS 	| DNS for Dremio Environment 	| No 	|

2. Log into Azure using Azure CLI using either ```az account set -s $AZURE_SUB_ID && az login``` for User <br> or ```az login --service-principal -u $AAD_CLIENT_ID -p $AAD_SECRET --tenant $AAD_TENANT_ID``` for logging in using Service Principal
3. Deploy Azure Infrastructure and Dremio using ```sh ./deploy_dremio.sh```
4. Confirm Deployment was successful using ```kubectl get pods```
5. Check Dremio service is running using ```kubectl get svc``` and confirm it is running on your public IP address or a valid public IP address dependent on if the variable has been set.
6. Finally try to access Dremio using ```http(s)://{DREMIO_DNS}:9047```