import xml.etree.ElementTree as ET
import sys
from xml.dom import minidom
import json
import yaml

def build_config_xml(storage_account, client_id, secret, tenant_id, path):
    root = ET.Element('configuration')
    names = [
        {
            "name": "fs.dremioAzureStorage.impl",
            "description": "FileSystem implementation. Must always be com.dremio.plugins.azure.AzureStorageFileSystem",
            "value": "com.dremio.plugins.azure.AzureStorageFileSystem"
        },
        {
            "name": "dremio.azure.account",
            "description": "The name of the storage account.",
            "value": f"{storage_account}"
        },
        {
            "name": "dremio.azure.mode",
            "description": "The storage account type. Value: STORAGE_V1 or STORAGE_V2",
            "value": "STORAGE_V2"
        },
        {
            "name": "dremio.azure.secure",
            "description": "Boolean option to enable SSL connections. Default: True, Value: True/False",
            "value": "True"
        },
        {
            "name": "dremio.azure.credentialsType",
            "description": "The credentials used for authentication. Value: ACCESS_KEY or AZURE_ACTIVE_DIRECTORY",
            "value": "AZURE_ACTIVE_DIRECTORY"
        },
        {
            "name": "dremio.azure.clientId",
            "description": "The client ID of the Azure application used for Azure Active Directory",
            "value": f"{client_id}"
        },
        {
            "name": "dremio.azure.tokenEndpoint",
            "description": "OAuth 2.0 token endpoint for Azure Active Directory(v1.0)",
            "value": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
        },
        {
            "name": "dremio.azure.clientSecret",
            "description": "The client secret of the Azure application used for Azure Active Directory",
            "value": f"{secret}"
        }
    ]
    for property in names:
        prop_root = ET.SubElement(root, 'property')
        # create property
        for k, v in property.items():
            ET.SubElement(prop_root, k).text = v
    xmlstr = minidom.parseString(ET.tostring(root)).toprettyxml(indent="   ")
    full_path = path+'/config/core-site.xml'
    with open(full_path, 'w') as f:
        f.write(xmlstr)

def build_azuread(client_id, secret, redirect_url, tenant_id, path):
    config = {
        "oAuthConfig": {
            "clientId": f"{client_id}",
            "clientSecret": f"{secret}",
            "redirectUrl": redirect_url,
            "authorityUrl": f"https://login.microsoftonline.com/{tenant_id}/v2.0",
            "scope": "openid profile offline_access",
            "jwtClaims": {
                "userName": "preferred_username"
            }
        }
    }
    full_path = path + '/config/azuread.json'
    with open(full_path, 'w') as f:
        f.write(json.dumps(config, indent=4, sort_keys=True))

def load_yaml(conf_file):
    try:
        with open(conf_file) as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print(e)
    finally:
        return config

def write_yaml(config_file, conf):
    try:
        with open(config_file, 'wb') as f:
            yaml.dump(conf, f, encoding="utf-8")
    except Exception as e:
        print(e)

def recursive_update(doc, prop, value, m , depth):
    if prop not in doc:
        doc[a] = {}
    tmp = doc[a]
    if m == depth:
        tmp = value
        return tmp
    return recursive_update(tmp, prop, value, m+1, depth)

def update_yaml_props(doc, props):
    for prop in props:
        k,v = prop.split("=")
        tmp = k.split(".")
        if len(tmp) == 1:
            doc[k] = v
        else:
            pass
    print(doc)
    return doc

def set_executor_props(docs, *args):
    executor = docs['executor']
    props = args[0]
    return update_yaml_props(executor, props)


if __name__ == "__main__":
    args = sys.argv
    if args[1] == "core-site":
        storage_account, client_id, secret, tenant_id, path = args[2:]
        build_config_xml(storage_account, client_id, secret, tenant_id, path)
    elif args[1] == "azuread":
        client_id, secret, redirect_url, tenant_id, path = args[2:]
        build_azuread(client_id, secret, redirect_url, tenant_id, path)
    elif args[1] == "dremio_conf":
        data = load_yaml(args[2])
        # perform manipulation
        a = set_executor_props(data, args[3:])
        # save update config
    else:
        print("""
        Usage:
            python create_dremio_config.py [command]
        
        Available Commands:
            core-site [args] - create a core-site.xml configuration file for Dremio
            azuread [args] - create an azure ad configuration file for Dremio
        """)