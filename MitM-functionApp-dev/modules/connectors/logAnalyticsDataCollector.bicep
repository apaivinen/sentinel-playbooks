param logAnalyticsConnName string = 'azureloganalyticsdatacollector'
param location string
param subscriptionId string = subscription().subscriptionId
param tags object

resource connections_logAnalytics 'Microsoft.Web/connections@2016-06-01' = {
  name: logAnalyticsConnName
  location: location
  tags:tags
  kind: 'V1'
  properties: {
    displayName: logAnalyticsConnName
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {
      username: 'PLACEHOLDER'
    }
    api: {
      name: logAnalyticsConnName
      displayName: 'Azure Log Analytics Data Collector'
      description: 'Azure Log Analytics Data Collector will send data to any Azure Log Analytics workspace.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1652/1.0.1652.3394/azureloganalyticsdatacollector/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureloganalyticsdatacollector'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
