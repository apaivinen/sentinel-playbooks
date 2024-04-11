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
param servicePrefix string

@description('Required. General name of the service.')
param Name string = 'Block-EntraIdUser'


@description('Required. Defined in parameter file. The trigger type (e.g. "Incident" or "Entity")')
@allowed(['Incident','Entity',''])
param TriggerType string

@description('Workflow actions. Defined in parameter file.')
param WorkflowActions object

//
// Optional and dynamic parameters. Change only if necessary
//
@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Tags for all resources within Azure Function App module.')
param tags object = {resource:'${servicePrefix}-${Name}-${TriggerType}'}

//
// Variables for naming
//
var prefix = servicePrefix == '' ? '' : '${servicePrefix}-'
var logicAppName =  replace('${prefix}${Name}-Playbook-${TriggerType}',' ','')



//
// Load and create a Logic App
//
module LogicApp 'res/logic/workflow/main.bicep' = {
  name: logicAppName
  scope: resourceGroup(resourceGroupName)
  params:{
    name: logicAppName
    location: location
    tags: tags
    workflowActions: WorkflowActions
    managedIdentities: {
      systemAssigned:true
    }
  }
}
