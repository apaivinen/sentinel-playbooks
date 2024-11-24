metadata name = 'Unblock Entra ID user by using conditional access with entity trigger'
metadata description = 'This Bicep template deploys a Sentinel playbook that unblocks Entra ID user access to all cloud resources using conditional access. The playbook is triggered from an entity.'
metadata author = 'Anssi Päivinen'
metadata Created = '24.11.2024'
metadata Modified = '24.11.2024'
metadata ChangeReason = 'Initial bicep development'

targetScope = 'resourceGroup'

@description('Define a prefix to be attached to every service name')
param servicePrefix string = ''

@description('Specifies who created the resource. This is used in Tags')
param createdBy string = 'Anonymous'

@description('Define a group id for Microsoft Entra ID group which is used in Conditional Access policy to block users')
param groupId string = 'INSERT-YOUR-GROUPID-HERE'

@description('Define a name for resource group. By default uses the current resource group name')
param resourceGroup string = az.resourceGroup().name

@description('Specifies the location for resources. by default uses the current resource group location')
param location string = az.resourceGroup().location

@description('The deployment timestamp')
param deploymentTimestamp string = utcNow() // Example: 20241123T210053Z

var LogicAppname = empty(servicePrefix) ? 'Unblock-User-ConditionalAccess-Entity' : '${servicePrefix}-Unblock-User-ConditionalAccess-Entity'

var year = substring(deploymentTimestamp, 0, 4)          // Extracts '2024'
var month = substring(deploymentTimestamp, 4, 2)         // Extracts '11'
var day = substring(deploymentTimestamp, 6, 2)           // Extracts '23'
var formattedDate = '${day}.${month}.${year}'            // '23.11.2024'



resource sentinelConnector 'Microsoft.Web/connections@2016-06-01' = {
  name: LogicAppname
  location: location
  tags: {
    Playbook: LogicAppname
    createdBy: createdBy
    createdOn: formattedDate
  }
  kind: 'V1'
  properties: {
    displayName: LogicAppname
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    parameterValueType: 'Alternative'
    api: {
      name: 'azuresentinel'
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1718/1.0.1718.3951/azuresentinel/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}


resource LogicApp 'Microsoft.Logic/workflows@2017-07-01' = {
  name: LogicAppname
  dependsOn:[
    sentinelConnector
  ]
  location: location
  tags: {
    Playbook: LogicAppname
    createdBy: createdBy
    createdOn: formattedDate
  }
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
        Microsoft_Sentinel_entity: {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            body: {
              callback_url: '@listCallbackUrl()'
            }
            path: '/entity/@{encodeURIComponent(\'Account\')}'
          }
        }
      }
      actions: {
        'Initialize_variable_-_GroupId': {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'GroupId'
                type: 'string'
                value: groupId
              }
            ]
          }
        }
        'HTTP_-_Remove_user_from_group': {
          runAfter: {
            'Initialize_variable_-_GroupId': [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            uri: 'https://graph.microsoft.com/v1.0/groups/@{variables(\'GroupId\')}/members/@{triggerBody()?[\'Entity\']?[\'properties\']?[\'AadUserId\']}/$ref'
            method: 'DELETE'
            headers: {
              'Content-type': ' application/json'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://graph.microsoft.com'
            }
          }
          runtimeConfiguration: {
            contentTransfer: {
              transferMode: 'Chunked'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
            connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Web/connections/${LogicAppname}'
            connectionName: LogicAppname
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
                //identity: LogicAppname
              }
            }
          }
        }
      }
    }
  }
}
