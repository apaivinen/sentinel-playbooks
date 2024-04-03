param connectorName string = 'SentinelConnector'
param location string
param subscriptionId string = subscription().subscriptionId
param tags object

resource sentinelconnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azuresentinel'
  location: location
  tags:tags
  properties: {
    displayName: connectorName
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    api: {
      name: 'azuresentinel'
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1677/1.0.1677.3631/${connectorName}/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

output ConnectorIDURI string = sentinelconnection.properties.api.id
