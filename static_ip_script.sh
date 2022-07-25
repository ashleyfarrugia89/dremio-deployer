AKS_CLUSTER_NAME=AF_Field_EMEA_AKS_Cluster
AKS_RESOURCE_GROUP=AF_Field_EMEA_rg
PIP_RESOURCE_GROUP=$(az aks show --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup --output tsv)
CLIENT_ID=$(az aks show --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
SUB_ID=$(az account show --query "id" --output tsv)


az role assignment create \
	--assignee $CLIENT_ID \
	--role "Network Contributor" \
	--scope /subscriptions/$SUB_ID/resourceGroups/$PIP_RESOURCE_GROUP
