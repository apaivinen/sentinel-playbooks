param workflows_dev_Block_EntraIdUser_Playbook_Entity_name string = 'dev-Block-EntraIdUser-Playbook-Entity'
param sentinelConnExternalId string = '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/resourceGroups/RG-TenantSentinel-Playbooks/providers/Microsoft.Web/connections/microsoftsentinel-Block-EntraIDUser-EntityTrigger'
param location string
resource workflows_dev_Block_EntraIdUser_Playbook_Entity_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_dev_Block_EntraIdUser_Playbook_Entity_name
  location: 'westeurope'
  tags: {
    resource: 'dev-Block-EntraIdUser-Entity'
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
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
            connectionId: sentinelConnExternalId
            connectionName: 'microsoftsentinel-Block-EntraIDUser-EntityTrigger'
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
