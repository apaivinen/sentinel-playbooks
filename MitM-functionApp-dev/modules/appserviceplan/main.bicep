@description('Required. Name for the App service plan.')
@maxLength(64)
param name string

@description('Required. Location for all resources.')
param location string

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {}

@description('Required. Defines the name, tier, size, family and capacity of the app service plan.')
param sku object = {
  name: 'Y1'
  tier: 'Dynamic'
  size: 'Y1'
  family: 'Y'
  capacity: 0
}

@description('Optional. Kind of server OS.')
@allowed([ 'Windows', 'Linux' ])
param serverOS string = 'Windows'

@description('The kind of resource. Empty string means windows.')
var servicePlanKind = serverOS == 'Linux' ? toLower(serverOS) : ''

@description('Optional. If true, apps assigned to this app service plan can be scaled independently. If false, apps assigned to this app service plan will scale to all instances of the plan.')
param perSiteScaling bool = false

@description('Optional. Maximum number of total workers allowed for this ElasticScaleEnabled app service plan.')
param maximumElasticWorkerCount int = 0

@description('Optional. Scaling worker count.')
param targetWorkerCount int = 0

@description('Optional. The instance size of the hosting plan (small, medium, or large).')
@allowed([ 0, 1, 2 ])
param targetWorkerSizeId int = 0

@description('Defines Application service plan.')
resource serverfarms 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: servicePlanKind
  //kind: 'functionapp' //alkuperäisessä tämä oli kovakoodattuna
  properties: {
    perSiteScaling: perSiteScaling
    maximumElasticWorkerCount: maximumElasticWorkerCount
    targetWorkerCount: targetWorkerCount
    targetWorkerSizeId: targetWorkerSizeId
    elasticScaleEnabled: false
    zoneRedundant: false
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
  }
}

output serverfarmsId string = serverfarms.id
