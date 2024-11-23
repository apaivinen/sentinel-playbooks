metadata name = 'Block Entra ID user with incident trigger'
metadata description = 'This bicep deploys Sentinel playbook for blocking Entra ID user with incident trigger'
metadata author = 'Anssi Päivinen'
metadata Created = '23.11.2024'

targetScope = 'resourceGroup'

@description('Define a prefix to be attached to every service name')
param servicePrefix string = ''

@description('Specifies who created the resource. This is used in Tags')
param createdBy string = 'Anssi'

@description('Define a name for resource group. By default uses the current resource group name')
param resourceGroup string = az.resourceGroup().name

@description('Specifies the location for resources. by default uses the current resource group location')
param location string = az.resourceGroup().location

@description('The deployment timestamp')
param deploymentTimestamp string = utcNow() // Example: 20241123T210053Z

var LogicAppname = empty(servicePrefix) ? 'Block-EntraIDUser-Incident' : '${servicePrefix}-Block-EntraIDUser-Incident'
var sentinelConnectorName = '${LogicAppname}'
var year = substring(deploymentTimestamp, 0, 4)          // Extracts '2024'
var month = substring(deploymentTimestamp, 4, 2)         // Extracts '11'
var day = substring(deploymentTimestamp, 6, 2)           // Extracts '23'
var formattedDate = '${day}.${month}.${year}'            // '23.11.2024'



resource sentinelConnector 'Microsoft.Web/connections@2016-06-01' = {
  name: sentinelConnectorName
  location: location
  tags: {
    Playbook: LogicAppname
    createdBy: createdBy
    createdOn: formattedDate
  }
  kind: 'V1'
  properties: {
    displayName: sentinelConnectorName
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
        Microsoft_Sentinel_incident: {
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
            path: '/incident-creation'
          }
        }
      }
      actions: {
        'Entities_-_Get_Accounts': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: '@triggerBody()?[\'object\']?[\'properties\']?[\'relatedEntities\']'
            path: '/entities/account'
          }
        }
        'Initialize_variable_-_ErrorArray': {
          runAfter: {
            'Entities_-_Get_Accounts': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorArray'
                type: 'array'
              }
            ]
          }
        }
        'Initialize_variable_-_SuccessArray': {
          runAfter: {
            'Initialize_variable_-_ErrorArray': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'SuccessArray'
                type: 'array'
              }
            ]
          }
        }
        'Compose_-_DEBUG_-_list_of_accounts': {
          runAfter: {
            'Initialize_variable_-_SuccessArray': [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '@body(\'Entities_-_Get_Accounts\')?[\'Accounts\']'
        }
        For_each: {
          foreach: '@body(\'Entities_-_Get_Accounts\')?[\'Accounts\']'
          actions: {
            'HTTP_-_Block_user': {
              type: 'Http'
              inputs: {
                uri: 'https://graph.microsoft.com/v1.0/users/@{items(\'For_each\')?[\'AadUserId\']}'
                method: 'PATCH'
                body: {
                  accountEnabled: '@false'
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
            'Append_to_array_variable_-_SuccessArray': {
              runAfter: {
                'HTTP_-_Block_user': [
                  'Succeeded'
                ]
              }
              type: 'AppendToArrayVariable'
              inputs: {
                name: 'SuccessArray'
                value: 'User <b>@{item()?[\'Name\']}</b> was successfully disabled.<br />'
              }
            }
            'Append_to_array_variable_-_ErrorArray': {
              runAfter: {
                'Parse_JSON_-_Error_message': [
                  'Succeeded'
                ]
              }
              type: 'AppendToArrayVariable'
              inputs: {
                name: 'ErrorArray'
                value: 'User <b>@{item()?[\'Name\']}</b> was <b><em>not disabled</em></b>. <br /><b>Error message:</b> @{body(\'Parse_JSON_-_Error_message\')?[\'error\']?[\'message\']}<br />'
              }
            }
            'Parse_JSON_-_Error_message': {
              runAfter: {
                'HTTP_-_Block_user': [
                  'Failed'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP_-_Block_user\')'
                schema: {
                  type: 'object'
                  properties: {
                    error: {
                      type: 'object'
                      properties: {
                        code: {
                          type: 'string'
                        }
                        message: {
                          type: 'string'
                        }
                        innerError: {
                          type: 'object'
                          properties: {
                            date: {
                              type: 'string'
                            }
                            'request-id': {
                              type: 'string'
                            }
                            'client-request-id': {
                              type: 'string'
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          runAfter: {
            'Compose_-_DEBUG_-_list_of_accounts': [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        'Add_comment_to_incident_(V3)': {
          runAfter: {
            For_each: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              incidentArmId: '@triggerBody()?[\'object\']?[\'id\']'
              message: '@{if(empty(variables(\'SuccessArray\')),\'\',join(variables(\'SuccessArray\'),\',\'))}<br><br>@{if(empty(variables(\'ErrorArray\')),\'\',join(variables(\'ErrorArray\'),\',\'))}'
            }
            path: '/Incidents/Comment'
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
            connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Web/connections/${sentinelConnectorName}'
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
