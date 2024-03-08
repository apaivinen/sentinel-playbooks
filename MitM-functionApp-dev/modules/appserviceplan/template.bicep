param serverfarms_ASP_DEVmitmbusting_95ed_name string = 'ASP-DEVmitmbusting-95ed'

resource serverfarms_ASP_DEVmitmbusting_95ed_name_resource 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: serverfarms_ASP_DEVmitmbusting_95ed_name
  location: 'West Europe'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}
