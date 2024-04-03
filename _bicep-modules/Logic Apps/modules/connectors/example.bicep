param connections_azuresentinel_name string = 'azuresentinel'

resource connections_azuresentinel_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_azuresentinel_name
  location: 'westeurope'
  kind: 'V1'
  properties: {
    displayName: 'Sentinel-name-LogicApp-env'
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    createdTime: '2024-03-23T12:03:42.7827234Z'
    changedTime: '2024-03-23T12:03:42.7827234Z'
    api: {
      name: connections_azuresentinel_name
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1677/1.0.1677.3631/${connections_azuresentinel_name}/icon.png'
      brandColor: '#0072C6'
      id: '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/providers/Microsoft.Web/locations/westeurope/managedApis/${connections_azuresentinel_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
