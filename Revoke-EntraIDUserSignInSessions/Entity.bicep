metadata name = 'Revoke user session with entity trigger'
metadata description = 'This bicep deploys Sentinel playbook for revoking user sessions with entity trigger'
metadata author = 'Anssi Päivinen'
metadata Created = '24.11.2024'
metadata Modified = '24.11.2024'
metadata ChangeReason = 'initial bicep template development'

targetScope = 'resourceGroup'

@description('Define a prefix to be attached to every service name')
param servicePrefix string = ''

@description('Specifies who created the resource. This is used in Tags')
param createdBy string = 'Anonymous'

@description('Define a name for resource group. By default uses the current resource group name')
param resourceGroup string = az.resourceGroup().name

@description('Specifies the location for resources. by default uses the current resource group location')
param location string = az.resourceGroup().location

@description('The deployment timestamp')
param deploymentTimestamp string = utcNow() // Example: 20241123T210053Z

var LogicAppname = empty(servicePrefix) ? 'Revoke-UserSessions-Entity' : '${servicePrefix}-Revoke-UserSessions-Entity'

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
              callback_url: '@{listCallbackUrl()}'
            }
            path: '/entity/@{encodeURIComponent(\'Account\')}'
          }
        }
      }
      actions: {
        'Compose_-_concat_UPN': {
          runAfter: {}
          type: 'Compose'
          inputs: '@concat(triggerBody()?[\'Entity\']?[\'properties\']?[\'Name\'],\'@\',triggerBody()?[\'Entity\']?[\'properties\']?[\'UPNSuffix\'])'
        }
        'HTTP_-_Revoke_sessions': {
          runAfter: {
            'Compose_-_concat_UPN': [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            uri: 'https://graph.microsoft.com/v1.0/users/@{outputs(\'Compose_-_concat_UPN\')}/revokeSignInSessions'
            method: 'POST'
            headers: {
              'Content-Type': 'application/json'
            }
            authentication: {
              audience: 'https://graph.microsoft.com'
              type: 'ManagedServiceIdentity'
            }
          }
        }
        Condition: {
          actions: {
            Terminate: {
              type: 'Terminate'
              inputs: {
                runStatus: 'Succeeded'
              }
            }
          }
          runAfter: {
            'HTTP_-_Revoke_sessions': [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              'Add_comment_to_incident_(V3)': {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
                    }
                  }
                  method: 'post'
                  body: {
                    incidentArmId: '@triggerBody()?[\'IncidentArmID\']'
                    message: '<p><span style="white-space: pre-wrap;">User </span>@{outputs(\'Compose_-_concat_UPN\')}<span style="white-space: pre-wrap;"> sign in sessions were revoked in EntraID</span></p>'
                  }
                  path: '/Incidents/Comment'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'IncidentArmID\']'
                  '@null'
                ]
              }
            ]
          }
          type: 'If'
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
