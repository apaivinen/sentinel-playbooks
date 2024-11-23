param playbookName string = 'MDfE-UnisolateMachine'
param sentinelConnectionName string = 'uai-sentinel'
param userAssignedIdentityName string = 'uai-sentinel'
@description('TenantId of the tenant with the application registration that has the necessary permissions (Machine.Isolate)')
param tenantId string
@description('Client id of the application registration that has the necessary permissions (Machine.Isolate)')
param clientId string
@description('Client secret of the application registration that has the necessary permissions (Machine.Isolate)')
@secure()
param clientSecret string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location
}


resource uaiAuthorization 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id)
  properties:{
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/3e150937-b8fe-4cfb-8069-0eaf05ecd056' // Add Azure Sentinel Responder role to the UAI
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource sentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: sentinelConnectionName
  location: resourceGroup().location
  properties: {
    displayName: 'Azure Sentinel Playbook UAI'
    parameterValueType: 'Alternative'
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
    }
  }
}


resource playbook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: playbookName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    state: 'Enabled'
    parameters:{
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: sentinelConnection.id
            connectionName: sentinelConnection.name
            connectionProperties: {
              authentication: {
                identity: userAssignedIdentity.id
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
          }
        }
      }
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        tenantId: {
          type: 'string'
          defaultValue: tenantId
        }
        clientId: {
          type: 'string'
          defaultValue: clientId
        }
        clientSecret: {
          type: 'string'
          defaultValue: clientSecret
        }
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_response_to_an_Azure_Sentinel_alert_is_triggered: {
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
            path: '/subscribe'
          }
        }
      }
      actions: {
        'Alert_-_Get_incident': {
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/Incidents/subscriptions/@{encodeURIComponent(triggerBody()?[\'WorkspaceSubscriptionId\'])}/resourceGroups/@{encodeURIComponent(triggerBody()?[\'WorkspaceResourceGroup\'])}/workspaces/@{encodeURIComponent(triggerBody()?[\'WorkspaceId\'])}/alerts/@{encodeURIComponent(triggerBody()?[\'SystemAlertId\'])}'
          }
          runAfter: {}
          type: 'ApiConnection'
        }
        'Entities_-_Get_hosts': {
          runAfter: {
            'Alert_-_Get_incident': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()?[\'Entities\']'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/entities/host'
          }
        }
        For_each: {
          foreach: '@body(\'Entities_-_Get_Hosts\')?[\'Hosts\']'
          runAfter: {
            'Entities_-_Get_Hosts': [
              'Succeeded'
            ]
          }
          type: 'Foreach'
          actions: {
            Condition: {
              actions: {
                'Add_comment_to_incident_(V3)': {
                  inputs: {
                    body: {
                      incidentArmId: '@body(\'Alert_-_Get_incident\')?[\'id\']'
                      message: '<p>Host [@{items(\'For_each\')?[\'HostName\']}] have been <strong>released from isolation</strong>.</p>'
                    }
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    path: '/Incidents/Comment'
                  }
                  runAfter: {}
                  type: 'ApiConnection'
                }
              }
              else: {
                actions: {
                  'Add_comment_to_incident_(V3)_2': {
                    inputs: {
                      body: {
                        incidentArmId: '@body(\'Alert_-_Get_incident\')?[\'id\']'
                        message: '<p><strong>Failed</strong> to release host [@{items(\'For_each\')?[\'HostName\']}] from isolation.<br>\n<br>\n<strong>Http status code</strong>: @{outputs(\'Unisolate_machine\')[\'statusCode\']}<br>\n<strong>Error message</strong>: @{body(\'Unisolate_machine\')?[\'body\']?[\'error\']?[\'message\']}</p>'
                      }
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
                        }
                      }
                      method: 'post'
                      path: '/Incidents/Comment'
                    }
                    runAfter: {}
                    type: 'ApiConnection'
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@outputs(\'Unisolate_machine\')[\'statusCode\']'
                      201
                    ]
                  }
                ]
              }
              runAfter: {
                Unisolate_machine: [
                  'Succeeded'
                ]
              }
              type: 'If'
            }
            Unisolate_machine: {
              inputs: {
                authentication: {
                  audience: 'https://api.securitycenter.microsoft.com'
                  clientId: '@parameters(\'clientId\')'
                  secret: '@parameters(\'clientSecret\')'
                  tenant: '@parameters(\'tenantId\')'
                  type: 'ActiveDirectoryOAuth'
                }
                body: {
                  Comment: 'Azure Sentinel playbook released machine from isolation due to incident @{body(\'Alert_-_Get_incident\')?[\'properties\']?[\'incidentNumber\']}'
                }
                method: 'POST'
                uri: 'https://api-eu.securitycenter.microsoft.com/api/machines/@{body(\'Parse_JSON\')?[\'MdatpDeviceId\']}/unisolate'
              }
              runAfter: {
                Parse_JSON: [
                  'Succeeded'
                ]
              }
              type: 'Http'
            }
            Parse_JSON: {
              inputs: {
                content: '@items(\'For_each\')'
                schema: {
                  properties: {
                    '$id': {
                      type: 'string'
                    }
                    AadDeviceId: {}
                    AvStatus: {
                      type: 'string'
                    }
                    FQDN: {
                      type: 'string'
                    }
                    HealthStatus: {
                      type: 'string'
                    }
                    HostName: {
                      type: 'string'
                    }
                    LastExternalIpAddress: {
                      type: 'string'
                    }
                    LastIpAddress: {
                      type: 'string'
                    }
                    LastSeen: {
                      type: 'string'
                    }
                    MdatpDeviceId: {
                      type: 'string'
                    }
                    OSFamily: {
                      type: 'string'
                    }
                    OSVersion: {
                      type: 'string'
                    }
                    OnboardingStatus: {
                      type: 'string'
                    }
                    RiskScore: {
                      type: 'string'
                    }
                    Tags: {
                      items: {
                          type: 'string'
                      }
                      type: 'array'
                    }
                    Type: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
              runAfter: {}
              type: 'ParseJson'
            }
          }
        }
      }
      outputs: {}
    }
  }
}
