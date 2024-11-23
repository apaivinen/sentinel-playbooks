param connections_MicrosoftSentinel_name string = 'MicrosoftSentinel3'

resource connections_MicrosoftSentinel_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_MicrosoftSentinel_name
  location: 'westeurope'
  properties: {
    displayName: connections_MicrosoftSentinel_name
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
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1685/1.0.1685.3700/azuresentinel/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
