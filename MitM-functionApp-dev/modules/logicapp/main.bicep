param logicAppName string
param resourceGroupName string
param location string
param subscriptionId string = subscription().subscriptionId
param logAnalyticsConnName string
param logAnalyticsConnectorID string = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/connections/${logAnalyticsConnName}'
@description('Tags')
param tags object

resource workflows_p_mgt_MITM_detection_logicapp_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicAppName
  tags: tags
  location: location
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
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'GET'
            schema: {}
          }
        }
      }
      actions: {
        'Condition_check_-_REFERER': {
          actions: {}
          runAfter: {
            Parse_JSON_HTTP_Headers: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Terminate: {
                runAfter: {}
                type: 'Terminate'
                inputs: {
                  runStatus: 'Cancelled'
                }
              }
            }
          }
          expression: {
            and: [
              {
                not: {
                  equals: [
                    '@body(\'Parse_JSON_HTTP_Headers\')?[\'Referer\']'
                    'https://login.microsoftonline.com/'
                  ]
                }
              }
              {
                not: {
                  equals: [
                    '@body(\'Parse_JSON_HTTP_Headers\')?[\'Referer\']'
                    'https://login.microsoft.com/'
                  ]
                }
              }
              {
                not: {
                  equals: [
                    '@body(\'Parse_JSON_HTTP_Headers\')?[\'Referer\']'
                    '@null'
                  ]
                }
              }
              {
                not: {
                  endsWith: [
                    '@body(\'Parse_JSON_HTTP_Headers\')?[\'Referer\']'
                    '.logic.azure.com/'
                  ]
                }
              }
            ]
          }
          type: 'If'
        }
        Initialize_variable_JsonBodyLogs: {
          runAfter: {
            'Condition_check_-_REFERER': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'JsonBodyLogs'
                type: 'string'
                value: '{\n"LureType": "MITM Detection Custom CSS",\n"Referer":"@{body(\'Parse_JSON_HTTP_Headers\')?[\'Referer\']}",\n"Clientip": "@{body(\'Parse_JSON_HTTP_Headers\')?[\'CLIENT-IP\']}",\n"UserAgent": "@{body(\'Parse_JSON_HTTP_Headers\')?[\'User-Agent\']}",\n"DNSQueryResult":""\n}'
              }
            ]
          }
        }
        Initialize_variable_LogTableName: {
          runAfter: {
            Initialize_variable_JsonBodyLogs: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'LogTableName'
                type: 'string'
                value: 'AzureLure_CL'
              }
            ]
          }
        }
        Parse_JSON_HTTP_Headers: {
          runAfter: {}
          type: 'ParseJson'
          inputs: {
            content: '@triggerOutputs()[\'headers\']'
            schema: {
              properties: {
                Accept: {
                  type: 'string'
                }
                'Accept-Encoding': {
                  type: 'string'
                }
                'Accept-Language': {
                  type: 'string'
                }
                'CLIENT-IP': {
                  type: 'string'
                }
                'Content-Length': {
                  type: 'string'
                }
                'DISGUISED-HOST': {
                  type: 'string'
                }
                DNT: {
                  type: 'string'
                }
                Host: {
                  type: 'string'
                }
                'Max-Forwards': {
                  type: 'string'
                }
                Referer: {
                  type: 'string'
                }
                'Sec-Fetch-Dest': {
                  type: 'string'
                }
                'Sec-Fetch-Mode': {
                  type: 'string'
                }
                'Sec-Fetch-Site': {
                  type: 'string'
                }
                'Sec-GPC': {
                  type: 'string'
                }
                'User-Agent': {
                  type: 'string'
                }
                'WAS-DEFAULT-HOSTNAME': {
                  type: 'string'
                }
                'X-ARR-LOG-ID': {
                  type: 'string'
                }
                'X-ARR-SSL': {
                  type: 'string'
                }
                'X-AppService-Proto': {
                  type: 'string'
                }
                'X-Forwarded-For': {
                  type: 'string'
                }
                'X-Forwarded-Proto': {
                  type: 'string'
                }
                'X-Forwarded-TlsVersion': {
                  type: 'string'
                }
                'X-Original-URL': {
                  type: 'string'
                }
                'X-SITE-DEPLOYMENT-ID': {
                  type: 'string'
                }
                'X-WAWS-Unencoded-URL': {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Send_Data: {
          runAfter: {
            Initialize_variable_LogTableName: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: '@variables(\'JsonBodyLogs\')'
            headers: {
              'Log-Type': '@variables(\'LogTableName\')'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureloganalyticsdatacollector\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/api/logs'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureloganalyticsdatacollector: {
            connectionId: logAnalyticsConnectorID
            connectionName: logAnalyticsConnName
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureloganalyticsdatacollector'
          }
        }
      }
    }
  }
}
