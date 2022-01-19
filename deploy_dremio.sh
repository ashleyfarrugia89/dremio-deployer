#!/bin/bash

source dremio.local.config

# check service principal
if [[ "$AZURE_SP" = true ]]; then
  # service principal is not supported by terraform for azure backend so we need to define it using ARM see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform for details
  export ARM_CLIENT_ID=$AAD_CLIENT_ID
  export ARM_CLIENT_SECRET=$AAD_SECRET
  export ARM_SUBSCRIPTION_ID=$AZURE_SUB_ID
  export ARM_TENANT_ID=$AAD_TENANT_ID
  # login with service principal
  az login --service-principal -u $AAD_CLIENT_ID -p $AAD_SECRET --tenant $AAD_TENANT_ID
else
  # otherwise login with user
  az login
fi

# check if terraform has been initialised already
if [[ ! -d '.terraform' ]]; then
  if [[ ! "$PWD" = $DREMIO_TF_DIR ]]; then
    cd "$DREMIO_TF_DIR"
  fi
  terraform init -input=false -reconfigure
fi

# terraform deploy cluster
terraform apply -auto-approve \
-var "aad_group_id=$AAD_GROUP_NAME" \
-var "sp_client_id=$AAD_CLIENT_ID" \
-var "sp_secret=$AAD_SECRET" \
-var "application_name=$AAD_APP_NAME" \
-var "tenant_id=$AAD_TENANT_ID" \
-var "subscription_id=$AZURE_SUB_ID" \
-var "ssh_key=$SSH_KEY"

# get terraform outputs to configure dremio
export CLUSTER_NAME=$(terraform output -raw aks_cluster_name )
export AKS_RESOURCE_GROUP=$(terraform output -raw dremio_resource_group )
export NODE_RESOURCE_GROUP=$(terraform output -raw aks_node_pool_rg )
export PIP_IP_ADDRESS=$(terraform output -raw dremio_static_ip)

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

# deploy dremio
helm install "dremio" $DREMIO_CONF/dremio_v2 -f $DREMIO_CONF/dremio_v2/values.local.yaml \
--set service.loadBalancerIP=$PIP_IP_ADDRESS \
--set executor.memory=$EXECUTOR_MEMORY \
--set executor.cpu=$EXECUTOR_CPU \
--set coordinator.memory=$COORDINATOR_MEMORY \
--set coordinator.cpu=$COORDINATOR_CPU \
--set zookeeper.memory=$ZOOKEEPER_MEMORY \
--set zookeeper.cpu=$ZOOKEEPER_CPU \
--set service.annotations."service\.beta\.kubernetes\.io\/azure-load-balancer-resource-group"=$AKS_RESOURCE_GROUP \
--set image="dremio/dremio-ee" \
--set imageTag="19.2.0" \
--set imagePullSecrets.name="$DOCKER_SECRET_NAME"