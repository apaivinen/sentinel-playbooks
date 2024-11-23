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
var LogicAppName = replace('${prefix}${Name}-Playbook-${TriggerType}', ' ', '')
var SentinelConnectionName = 'MicrosoftSentinel'

module SentinelConnection 'res/web/connection/main.bicep' = {
  name: SentinelConnectionName
  params: {
    name: 'azuresentinel'
    displayName: SentinelConnectionName
    location: location
    statuses: [
      {
        status: 'Error'
        target: 'token'
        error: {}
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {}
    api: {
      name: 'azuresentinel'
      displayName: 'Microsoft Sentinel'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1685/1.0.1685.3700/azuresentinel/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

//
// Load and create a Logic App
//
module LogicApp 'res/logic/workflow/main.bicep' = {
  name: LogicAppName
  scope: resourceGroup(resourceGroupName)
  dependsOn: [SentinelConnection]
  params: {
    name: LogicAppName
    location: location
    tags: tags
    definitionParameters:{
      '$connections': {
        type: 'Object'
        defaultValue: {}
      }
    }
    workflowTriggers: {
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
    workflowActions: {
      'HTTP_-_Get_manager': {
        runAfter: {
          'Condition_-_Incident_ID_eq_null': [
            'Succeeded'
          ]
        }
        type: 'Http'
        inputs: {
          uri: 'https://graph.microsoft.com/v1.0/users/@{triggerBody()?[\'Entity\']?[\'properties\']?[\'AadUserId\']}/manager'
          method: 'GET'
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
      'Parse_JSON_-_Get_manager': {
        runAfter: {
          'HTTP_-_Get_manager': [
            'Succeeded'
          ]
        }
        type: 'ParseJson'
        inputs: {
          content: '@body(\'HTTP_-_Get_manager\')'
          schema: {
            type: 'object'
            properties: {
              id: {
                type: 'string'
              }
              userPrincipalName: {
                type: 'string'
              }
            }
          }
        }
      }
      'HTTP_-_Block_user': {
        runAfter: {}
        type: 'Http'
        inputs: {
          uri: 'https://graph.microsoft.com/v1.0/users/@{triggerBody()?[\'Entity\']?[\'properties\']?[\'AadUserId\']}'
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
      'Condition_-_Incident_ID_eq_null': {
        actions: {
          'Terminate_-_Incident_ID_is_null': {
            type: 'Terminate'
            inputs: {
              runStatus: 'Cancelled'
            }
          }
        }
        runAfter: {
          'HTTP_-_Block_user': [
            'Succeeded'
          ]
        }
        else: {
          actions: {}
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
      'Add_comment_to_incident_(V3)': {
        runAfter: {
          'Parse_JSON_-_Get_manager': [
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
            incidentArmId: '@triggerBody()?[\'IncidentArmID\']'
            message: '<p>User "@{concat(triggerBody()?[\'Entity\']?[\'properties\']?[\'Name\'],\'@\',triggerBody()?[\'Entity\']?[\'properties\']?[\'UPNSuffix\'])}" has been blocked.</p><p>According to Users profile information the users manager is "@{body(\'Parse_JSON_-_Get_manager\')?[\'userPrincipalName\']}"</p><br><p>Please take appropriate actions and contact the manager regarding the blocked user, along with any relevant information how to proceed with the blocked user.</p>'
          }
          path: '/Incidents/Comment'
        }
      }
    }
    managedIdentities: {
      systemAssigned: true
    }
    workflowParameters:{
      '$connections': {
        value: {
          azuresentinel: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
            connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/connections/${SentinelConnection.outputs.name}-${LogicAppName}'
            connectionName: SentinelConnection.outputs.name
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

