param connections_azuresentinel_name string = 'azuresentinel'

resource connections_azuresentinel_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_azuresentinel_name
  location: 'eastus'
  kind: 'V1'
  properties: {
    displayName: 'automaatio-yhteys'
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    createdTime: '2024-04-21T10:54:41.913971Z'
    changedTime: '2024-04-21T10:54:41.913971Z'
    api: {
      name: connections_azuresentinel_name
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1682/1.0.1682.3676/${connections_azuresentinel_name}/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/providers/Microsoft.Web/locations/eastus/managedApis/${connections_azuresentinel_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
