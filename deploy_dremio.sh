#!/bin/bash

source dremio.local.config

# function to create the terraform .tfvars file that will comprise variables used by terraform to deploy Dremio
function create_tf_vars() {
  # create empty file or empty existing file if exists
  echo -n "" > $1
  echo "aad_group_id=\"$AAD_GROUP_NAME\"" >> $1
  echo "sp_client_id=\"$AAD_CLIENT_ID\"" >> $1
  echo "sp_secret=\"$AAD_SECRET\"" >> $1
  echo "application_name=\"$AAD_APP_NAME\"" >> $1
  echo "tenant_id=\"$AAD_TENANT_ID\"" >> $1
  echo "subscription_id=\"$AZURE_SUB_ID\"" >> $1
  echo "environment_name=\"$ENV_PREFIX\"" >> $1
  echo "dremio_storage_account=\"$STORAGE_ACCOUNT\"" >> $1
  # check if SSH_KEY has been provided
  if [[ $SSH_KEY ]]; then
    echo "ssh_key=\"$SSH_KEY\"" >> $1
  fi
  # check if AZURE_RESOURCE_GROUP has been provided
  if [[ $AZURE_RESOURCE_GROUP ]]; then
    echo "azure_resource_group=\"$AZURE_RESOURCE_GROUP\"" >> $1
  fi
}

# create functions for Dremio deployment
function deploy_dremio_infra {
  # check if terraform has been initialised already
  if [[ ! -d '.terraform' ]]; then
    if [[ ! "$PWD" = $DREMIO_TF_DIR ]]; then
      cd "$DREMIO_TF_DIR"
    fi
    terraform init -input=false -reconfigure
  fi

  # check if user has provided their own storage account name
  if [[ $TF_STORAGE_ACCOUNT ]]; then
    # update main.tf file with the storage account details
    sed -i '' -e "s/dremiotfstorageaccount/$TF_STORAGE_ACCOUNT/g" main.tf
  fi

  #create tfvars file
  VAR_FILE="dremio_test.tfvars"
  create_tf_vars "$VAR_FILE"

  # check if user has provided their own resource group
  # if so import this resource into terraform and add a protected flag
  if [ $AZURE_RESOURCE_GROUP ] && [ $(az group exists --name $AZURE_RESOURCE_GROUP) = true ]; then
    # check if azure resource already exists, if so import resource into Terraform
    # set protected value in VAR_FILE
    echo "protected_rg=true" >> $VAR_FILE
    terraform import -var-file="$VAR_FILE" module.configure_resource_group.azurerm_resource_group.DREMIO_rg "/subscriptions/$AZURE_SUB_ID/resourceGroups/$AZURE_RESOURCE_GROUP"
  fi

  # deploy cluster
  terraform apply -var-file="$VAR_FILE"

  # get terraform outputs to configure dremio
  export CLUSTER_NAME=$(terraform output -raw aks_cluster_name )
  export AZURE_RESOURCE_GROUP=$(terraform output -raw dremio_resource_group )
  export NODE_RESOURCE_GROUP=$(terraform output -raw aks_node_pool_rg )
  export PIP_IP_ADDRESS=$(terraform output -raw dremio_static_ip)
  export STORAGE_ACCOUNT=$(terraform output -raw dremio_storage_account)
  export DREMIO_CONTAINER=$(terraform output -raw dremio_container)
}

function destroy_dremio_infra {
  #create tfvars file
  VAR_FILE="dremio_test.tfvars"
  create_tf_vars "$VAR_FILE"
  PROTECTED=False
  if [ $(az tag list --resource-id "/subscriptions/$AZURE_SUB_ID/resourceGroups/$AZURE_RESOURCE_GROUP" --query "properties.tags.Protected") ]; then
    # remove resource from config to protect the resource group
    terraform state rm module.configure_resource_group.azurerm_resource_group.DREMIO_rg
  fi
  # destroy provisioned resources for Dremio
  terraform destroy -auto-approve -var-file="$VAR_FILE"
}

# function to create authentication config for dremio
# variables:
# $1 - authentication type
# $2 - authentication file
function create_or_update_auth_conf() {
  # if auth conf exists update
  if [[ $(tail -n 1 $DREMIO_CONF/dremio_v2/config/dremio.conf) == services.coordinator.web.auth.config*  ]]; then
    # update
    sed -i '' -e "s/services.coordinator.web.auth.type.*/services.coordinator.web.auth.type:\ \"$1\"/" $DREMIO_CONF/dremio_v2/config/dremio.conf
    sed -i '' -e "s/services.coordinator.web.auth.config.*/services.coordinator.web.auth.config:\ \"$2\"/" $DREMIO_CONF/dremio_v2/config/dremio.conf
  # otherwise, create it
  else
    # create config
    # add azuread config to dremio.conf
    echo "" >> $DREMIO_CONF/dremio_v2/config/dremio.conf
    echo "services.coordinator.web.auth.type: \"$1\"" >> $DREMIO_CONF/dremio_v2/config/dremio.conf
    echo "services.coordinator.web.auth.config: \"$2\"" >> $DREMIO_CONF/dremio_v2/config/dremio.conf
  fi
}

function create_helm_chart() {
  # download and unzip dremio helm chart
  curl -LO  https://github.com/dremio/dremio-cloud-tools/archive/refs/heads/master.zip && unzip master.zip
  # set HELM_DIR for later
  tmp=$(pwd)
  DREMIO_CONF="$tmp/dremio-cloud-tools-master/charts/"
  # check if version is set, if not default to CE version and skip Azure AD integration
  if [[ -n $DREMIO_IMG ]] && [[ ($DREMIO_IMG == *"ee"*) || ($DREMIO_IMG == *"EE"*) ]]; then
    if [[ $AUTH_TYPE == 'aad' ]]; then
      # check is azure ad config has been added, if so then skip this step
      if [[ $(tail -n 1 $DREMIO_CONF/dremio_v2/config/dremio.conf) != "services.coordinator.web.auth.config: \"azuread.json\"" ]]; then
        create_or_update_auth_conf "azuread" "azuread.json"
      fi
      # create azuread.json - required for Azure AD SSO
      python create_dremio_config.py azuread $AAD_CLIENT_ID $AAD_SECRET $REDIRECT_URL $AAD_TENANT_ID $HELM_DIR
    elif [[ $AUTH_TYPE == 'ldap' ]]; then
      create_or_update_auth_conf "ldap" "ad.json"
    fi
    # create core-site.xml
    python create_dremio_config.py core-site $STORAGE_ACCOUNT $AAD_CLIENT_ID $AAD_SECRET $AAD_TENANT_ID $DREMIO_CONF/dremio_v2
  fi
  # check dremio resources are set if not set them
  EXECUTOR_MEMORY=${EXECUTOR_MEMORY:='4096'}
  EXECUTOR_CPU=${EXECUTOR_CPU:='2'}
  EXECUTOR_NODES=${EXECUTOR_NODES:='3'}
  COORDINATOR_MEMORY=${COORDINATOR_MEMORY:='4096'}
  COORDINATOR_CPU=${COORDINATOR_CPU:='2'}
  COORDINATOR_NODES=${COORDINATOR_NODES:='0'}
  ZOOKEEPER_MEMORY=${ZOOKEEPER_MEMORY:='1024'}
  ZOOKEEPER_CPU=${ZOOKEEPER_CPU:='0.5'}
  ZOOKEEPER_NODES=${ZOOKEEPER_NODES:='3'}
  # set docker defaults for dremio
  DREMIO_VERSION=${DREMIO_VERSION:='latest'}
  DREMIO_IMG=${DREMIO_IMG:='dremio/dremio-oss'}

  # update values.yaml configuration files
  sed -i '' -e "s/\#loadBalancerIP: 0.0.0.0/loadBalancerIP: $IP_ADDRESS/" $DREMIO_CONF/dremio_v2/values.yaml
  sed -i '' -e "s///" $DREMIO_CONF/dremio_v2/values.yaml
 }

function deploy_dremio {

  # create core-site.xml
  #python create_dremio_config.py core-site $STORAGE_ACCOUNT $AAD_CLIENT_ID $AAD_SECRET $AAD_TENANT_ID $DREMIO_CONF/dremio_v2
  # check dremio resources are set if not set them
  EXECUTOR_MEMORY=${EXECUTOR_MEMORY:='4096'}
  EXECUTOR_CPU=${EXECUTOR_CPU:='2'}
  EXECUTOR_NODES=${EXECUTOR_NODES:='3'}
  COORDINATOR_MEMORY=${COORDINATOR_MEMORY:='4096'}
  COORDINATOR_CPU=${COORDINATOR_CPU:='2'}
  COORDINATOR_NODES=${COORDINATOR_NODES:='0'}
  ZOOKEEPER_MEMORY=${ZOOKEEPER_MEMORY:='1024'}
  ZOOKEEPER_CPU=${ZOOKEEPER_CPU:='0.5'}
  ZOOKEEPER_NODES=${ZOOKEEPER_NODES:='3'}

  # set docker defaults for dremio
  DREMIO_VERSION=${DREMIO_VERSION:='latest'}
  DREMIO_IMG=${DREMIO_IMG:='dremio/dremio-oss'}

  # deploy dremio
  helm upgrade "dremio" $DREMIO_CONF/dremio_v2 -f $DREMIO_CONF/dremio_v2/values.yaml \
  --set service.loadBalancerIP=$PIP_IP_ADDRESS \
  --set executor.memory=$EXECUTOR_MEMORY \
  --set executor.cpu=$EXECUTOR_CPU \
  --set executor.count=$EXECUTOR_NODES \
  --set executor.nodeSelector.agentpool="executorpool" \
  --set executor.volumeSize="256Gi" \
  --set coordinator.nodeSelector.agentpool="coordpool" \
  --set coordinator.web.port=443 \
  --set coordinator.web.tls.enabled="true" \
  --set coordinator.web.tls.secret=$DOCKER_TLS_CERT_SECRET_NAME \
  --set coordinator.memory=$COORDINATOR_MEMORY \
  --set coordinator.cpu=$COORDINATOR_CPU \
  --set coordinator.count=$COORDINATOR_NODES \
  --set zookeeper.memory=$ZOOKEEPER_MEMORY \
  --set zookeeper.cpu=$ZOOKEEPER_CPU \
  --set zookeeper.count=$ZOOKEEPER_NODES \
  --set zookeeper.nodeSelector.agentpool="default" \
  --set service.annotations."service\.beta\.kubernetes\.io\/azure-load-balancer-resource-group"=$AZURE_RESOURCE_GROUP \
  --set image="$DREMIO_IMG" \
  --set imageTag="$DREMIO_VERSION" \
  --set imagePullSecrets.name="$DOCKER_SECRET_NAME" \
  --set distStorage.type="azureStorage" \
  --set distStorage.azureStorage.filesystem=$DREMIO_CONTAINER \
  --set distStorage.azureStorage.path="/"
}

# check user logged in, this code will return the username of the user already logged in
RES=$(az ad signed-in-user show --query userPrincipalName -o tsv)
if [[ $RES = "" ]]; then
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
fi

echo "What do you want to do?"
select yn in "Deploy" "Destroy" "Continue"; do
    case $yn in
        Deploy ) deploy_dremio_infra; break;;
        Destroy ) destroy_dremio_infra; exit;;
        Continue ) break;;
    esac
done

# check if it has failed to deploy Azure Infrastructure
if [[ -z $CLUSTER_NAME ]]; then
  echo "Failed to deploy or find a valid cluster"
  exit 1
fi

# get cluster credentials for kubectl
az aks get-credentials --name $CLUSTER_NAME --resource-group $AZURE_RESOURCE_GROUP --overwrite-existing

# add validation to check is docker image is CE or EE
if [[ $DREMIO_IMG == 'dremio/dremio-ee' ]]; then
  # create secret for ee version
  if [[ -n $DOCKER_USER ]]; then
    # create env variables for docker secret if required for Dremio EE
    export DOCKER_SECRET_NAME="dremio-docker-secret"
    kubectl create secret docker-registry "${DOCKER_SECRET_NAME}" --docker-username=$DOCKER_USER  --docker-password=$DOCKER_PASSWD --docker-email=$DOCKER_EMAIL
  fi
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

echo "Do you wish to build helm chart?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) create_helm_chart; break;;
        No ) exit;;
    esac
done

#echo "Do you wish to deploy Dremio?"
#select yn in "Yes" "No"; do
#    case $yn in
#        Yes ) deploy_dremio; break;;
#        No ) exit;;
#    esac
#done