metadata Name = 'Block entra id user'
metadata Description = 'This bicep deploys Sentinel block entra id user playbook resources.'
metadata Author = 'Anssi Päivinen'
metadata Created = '2024-04-11'
metadata sourceinformation = 'Everything under web-folder is from Azure Verified Modules. Rest of the files are by by author.'
metadata AVMGithublink = 'https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/web'

targetScope = 'resourceGroup'

//
// Deployment specific parameters. Modify values based on your needs
//
@description('Required. Defined in parameter file. Define a prefix to be attached to every service name. For example customer name abreviation')
param servicePrefix string = 'Dev'

@description('Required. General name of the service.')
param Name string = 'Block-EntraIdUser'

@description('Required. The trigger type')
@allowed(['Entity'])
param TriggerType string = 'Entity'

/*
@description('Workflow trigger. Defined in parameter file.')
param trigger object

@description('Workflow actions. Defined in parameter file.')
param WorkflowActions object
*/
//@description('Workflow Parameters. Defined in parameter file.')
//param WorkfloParameters object

//
// Optional and dynamic parameters. Change only if necessary
//
@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Tags for all resources within Azure Function App module.')
param tags object = { resource: '${servicePrefix}-${Name}-${TriggerType}' }

//
// Variables for naming
//
var prefix = servicePrefix == '' ? '' : '${servicePrefix}-'
var LogicAppName = replace('${prefix}${Name}-Playbook-${TriggerType}-aut', ' ', '')
var SentinelConnectionName = 'azuresentinel'


param workflows_automaatio_name string = 'automaatio'
param connections_azuresentinel_externalid string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/dev-template/providers/Microsoft.Web/connections/azuresentinel'


param connections_azuresentinel_name string = 'azuresentinel'

resource connections_azuresentinel_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_azuresentinel_name
  location: 'eastus'
  kind: 'V1'
  properties: {
    displayName: 'automaatio-yhteys'
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    createdTime: '2024-04-21T10:54:41.913971Z'
    changedTime: '2024-04-21T10:54:41.913971Z'
    api: {
      name: connections_azuresentinel_name
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1682/1.0.1682.3676/${connections_azuresentinel_name}/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/providers/Microsoft.Web/locations/eastus/managedApis/${connections_azuresentinel_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}


resource connection 'Microsoft.Web/connections@2016-06-01' = {
  name: SentinelConnectionName
  location: location
  kind: 'V1'
  properties: {
    displayName: 'azuresentinel'
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    api: {
      name: SentinelConnectionName
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1682/1.0.1682.3676/${SentinelConnectionName}/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${SentinelConnectionName}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}


resource playbook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: LogicAppName
  dependsOn:[connection]
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Microsoft_Sentinel_incident: {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            body: {
              callback_url: '@{listCallbackUrl()}'
            }
            path: '/incident-creation'
          }
        }
      }
      actions: {}
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
            connectionId: connections_azuresentinel_externalid
            connectionName: 'Microsoft Sentinel'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
        }
      }
    }
  }
}
