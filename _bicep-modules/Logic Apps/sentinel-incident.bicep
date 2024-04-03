param workflows_Leikkikentta_Logicapptesting_LogicApp_dev_name string = 'Leikkikentta-Logicapptesting-LogicApp-dev'
param connections_azuresentinel_externalid string = '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/resourceGroups/DEV-createTeams/providers/Microsoft.Web/connections/azuresentinel'

resource workflows_Leikkikentta_Logicapptesting_LogicApp_dev_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_Leikkikentta_Logicapptesting_LogicApp_dev_name
  location: 'westeurope'
  tags: {
    resource: 'Leikkikentta-Logicapptesting-dev'
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
        GraphAudience: {
          defaultValue: 'https://graph.microsoft.com'
          type: 'String'
        }
      }
      triggers: {
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
      actions: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: connections_azuresentinel_externalid
            connectionName: 'azuresentinel'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
          }
        }
      }
    }
  }
}
