param skuName string = 'B1'
param skuCapacity int = 1
param skuTier string = 'Basic'
param location string
param appServicePlanName string
param appServiceKind string

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
  }
  kind: appServiceKind
}

output appServicePlanID string = appServicePlan.id
