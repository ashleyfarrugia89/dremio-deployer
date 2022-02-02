#!/bin/bash

source dremio.local.config

# create functions for Dremio deployment
function deploy_dremio_infra {
  # check if terraform has been initialised already
  if [[ ! -d '.terraform' ]]; then
    if [[ ! "$PWD" = $DREMIO_TF_DIR ]]; then
      cd "$DREMIO_TF_DIR"
    fi
    terraform init -input=false -reconfigure
  fi

  # update main.tf file with the storage account details
  sed -i '' -e "s/dremiotfstorageaccount/$STORAGE_ACCOUNT/g" main.tf

  # deploy cluster with ssh_key using terraform
  if [[ $SSH_KEY ]]; then
    echo "Deploying cluster with SSH_KEY"
    terraform apply -auto-approve \
    -var "aad_group_id=$AAD_GROUP_NAME" \
    -var "sp_client_id=$AAD_CLIENT_ID" \
    -var "sp_secret=$AAD_SECRET" \
    -var "application_name=$AAD_APP_NAME" \
    -var "tenant_id=$AAD_TENANT_ID" \
    -var "subscription_id=$AZURE_SUB_ID" \
    -var "ssh_key=$SSH_KEY"
  else
    echo "Deploying cluster without SSH_KEY"
    terraform apply -auto-approve \
    -var "aad_group_id=$AAD_GROUP_NAME" \
    -var "sp_client_id=$AAD_CLIENT_ID" \
    -var "sp_secret=$AAD_SECRET" \
    -var "application_name=$AAD_APP_NAME" \
    -var "tenant_id=$AAD_TENANT_ID" \
    -var "subscription_id=$AZURE_SUB_ID"
  fi

  # get terraform outputs to configure dremio
  export CLUSTER_NAME=$(terraform output -raw aks_cluster_name )
  export AKS_RESOURCE_GROUP=$(terraform output -raw dremio_resource_group )
  export NODE_RESOURCE_GROUP=$(terraform output -raw aks_node_pool_rg )
  export PIP_IP_ADDRESS=$(terraform output -raw dremio_static_ip)
  export STORAGE_ACCOUNT=$(terraform output -raw dremio_storage_account)
  export DREMIO_CONTAINER=$(terraform output -raw dremio_container)
}

function deploy_dremio {
  # create core-site.xml
  python create_dremio_config.py core-site $STORAGE_ACCOUNT $AAD_CLIENT_ID $AAD_SECRET $AAD_TENANT_ID $DREMIO_CONF/dremio_v2
  # create azuread.json - required for Azure AD SSO
  python create_dremio_config.py azuread $AAD_CLIENT_ID $AAD_SECRET $REDIRECT_URL $AAD_TENANT_ID $DREMIO_CONF/dremio_v2
  # check dremio resources are set if not set them
  exec_mem=${EXECUTOR_MEMORY:='4096'}
  exec_cpu=${EXECUTOR_CPU:='2'}
  coord_mem=${COORDINATOR_MEMORY:='4096'}
  coord_cpu=${COORDINATOR_CPU:='2'}
  zook_mem=${ZOOKEEPER_MEMORY:='1024'}
  zook_cpu=${ZOOKEEPER_CPU:='0.5'}
  # deploy dremio
  helm install "dremio" $DREMIO_CONF/dremio_v2 -f $DREMIO_CONF/dremio_v2/values.yaml \
  --set service.loadBalancerIP=$PIP_IP_ADDRESS \
  --set executor.memory=$exec_mem \
  --set executor.cpu=$exec_cpu \
  --set executor.nodeSelector.agentpool="executorpool" \
  --set coordinator.nodeSelector.agentpool="coordpool" \
  --set coordinator.web.port=443 \
  --set coordinator.web.tls.enabled="true" \
  --set coordinator.web.tls.secret=$DOCKER_TLS_CERT_SECRET_NAME \
  --set coordinator.memory=$coord_mem \
  --set coordinator.cpu=$coord_cpu \
  --set zookeeper.memory=$zook_mem \
  --set zookeeper.cpu=$zook_cpu \
  --set zookeeper.nodeSelector.agentpool="default" \
  --set service.annotations."service\.beta\.kubernetes\.io\/azure-load-balancer-resource-group"=$AKS_RESOURCE_GROUP \
  --set image="dremio/dremio-ee" \
  --set imageTag="19.2.0" \
  --set imagePullSecrets.name="$DOCKER_SECRET_NAME" \
  --set distStorage.type="azureStorage" \
  --set distStorage.azureStorage.filesystem=$DREMIO_CONTAINER \
  --set distStorage.azureStorage.path="/"
}

# check service principal
if [[ "$AZURE_SP" = true ]]; then
  echo "Logging in with Service Principal"
  # service principal is not supported by terraform for azure backend so we need to define it using ARM see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform for details
  export ARM_CLIENT_ID=$AAD_CLIENT_ID
  export ARM_CLIENT_SECRET=$AAD_SECRET
  export ARM_SUBSCRIPTION_ID=$AZURE_SUB_ID
  export ARM_TENANT_ID=$AAD_TENANT_ID
  # login with service principal
  az login --service-principal -u $AAD_CLIENT_ID -p $AAD_SECRET --tenant $AAD_TENANT_ID
else
  # otherwise login with user
  echo "Logging in with User"
  az login && az account set -s $AZURE_SUB_ID
fi

echo "Do you wish to deploy Dremio Infrastructure?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) deploy_dremio_infra; break;;
        No ) exit;;
    esac
done

# check if it has failed to deploy Azure Infrastructure
if [[ -z $CLUSTER_NAME ]]; then
  echo "Failed to deploy or find a valid cluster"
  exit 1
fi

# get cluster credentials for kubectl
az aks get-credentials --name $CLUSTER_NAME --resource-group $AKS_RESOURCE_GROUP --overwrite-existing

# create secret for ee version
if [[ -n $DOCKER_USER ]]; then
  # create env variables for docker secret if required for Dremio EE
  export DOCKER_SECRET_NAME="dremio-docker-secret"
  kubectl create secret docker-registry "${DOCKER_SECRET_NAME}" --docker-username=$DOCKER_USER  --docker-password=$DOCKER_PASSWD --docker-email=$DOCKER_EMAIL
fi

# create secret for tls if required
if [[ -n $TLS_PRIVATE_KEY_PATH ]]; then
  # create env variables for TLS if required
  export DOCKER_TLS_CERT_SECRET_NAME="dremio-tls-secret-ui"
  kubectl create secret tls "${DOCKER_TLS_CERT_SECRET_NAME}" --key $TLS_PRIVATE_KEY_PATH --cert $TLS_CERT_PATH
fi

# assign AAD Client network contributor permissions on the AKS Node Resource Group
az role assignment create \
	--assignee $AAD_CLIENT_ID \
	--role "Network Contributor" \
	--scope /subscriptions/$AZURE_SUB_ID/resourceGroups/$NODE_RESOURCE_GROUP

echo "Do you wish to deploy Dremio?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) deploy_dremio; break;;
        No ) exit;;
    esac
done