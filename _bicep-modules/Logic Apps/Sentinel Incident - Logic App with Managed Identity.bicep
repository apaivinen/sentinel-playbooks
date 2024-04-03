metadata name = 'Logic app with managed identity'
metadata description = 'This bicep deploys blank logic app with managed identity.'
metadata author = 'Anssi Päivinen'
metadata Created = '2024-03-23'
metadata sourceinformation = 'Everything under logic-folder is from Azure Verified Modules. Rest of the files are by by author.'
metadata AVMGithublink = 'https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/web'

targetScope = 'resourceGroup'

@description('Required. Define a prefix to be attached to every service name. For example customer name abreviation')
param servicePrefix string = 'Leikkikentta'

@description('Name of the logic app')
param name string = 'LogicAppSentinelIncidentDemo'

@description('Required. The name of the target environment (e.g. "dev" or "prod")')
param deploymentEnvironment string = 'dev'

@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Tags for all resources within Azure Function App module.')
param tags object = { resource: '${servicePrefix}-${name}-${deploymentEnvironment}' }

var logicAppName = replace('${servicePrefix}-${name}-LogicApp-${deploymentEnvironment}', ' ', '')
var sentinelConnName = replace('${servicePrefix}-${name}-SentinelConnection', ' ', '')

@description('')
module sentinelConnection 'modules/connectors/sentinel.bicep' = {
  name: sentinelConnName
  params: {
    location: location
    tags: tags
    connectorName: sentinelConnName
    subscriptionId: subscription().subscriptionId
  }
}


@description('')
module logicapp 'modules/logic/workflow/main.bicep' = {
  name: logicAppName
  scope: resourceGroup(resourceGroupName)
  dependsOn:[
    sentinelConnection
  ]
  params: {
    name: logicAppName
    location: location
    managedIdentities: { systemAssigned: true }
    tags: tags
    workflowParameters: {
      GraphAudience: {
        defaultValue: 'https://graph.microsoft.com'
        type: 'String'
      }
    }
    workflowTriggers: {
      Microsoft_Sentinel_incident: {
        type: 'ApiConnectionWebhook'
        inputs: {
          body: {
            callback_url: '@{listCallbackUrl()}'
          }
          host: {
            connection: {
              name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
            }
          }
          path: '/incident-creation'
        }
      }
    }
  }
}
