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
param name string = 'Logicapptesting'

@description('Required. The name of the target environment (e.g. "dev" or "prod")')
param deploymentEnvironment string = 'dev'

@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Tags for all resources within Azure Function App module.')
param tags object = { resource: '${servicePrefix}-${name}-${deploymentEnvironment}' }

var logicAppName =  replace('${servicePrefix}-${name}-LogicApp-${deploymentEnvironment}',' ','')

module logicapp 'modules/logic/workflow/main.bicep' = {
  name: logicAppName
  scope: resourceGroup(resourceGroupName)
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
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
    }
  }
}
