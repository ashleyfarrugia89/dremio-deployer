#!/bin/bash
# set subscription id
az account set -s $AZURE_SUB_ID
az login
# create custom role --required if service principal does not have owner permissions on subscription, see https://docs.microsoft.com/en-us/azure/role-based-access-control/tutorial-custom-role-cli for details on creating a custom role
az role definition create --role-definition dremio-azcustom-role.json