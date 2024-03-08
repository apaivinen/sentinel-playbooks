param skuName string = 'Y1'
param skuCapacity int = 0
param skuTier string = 'Dynamic'
param location string
param appServicePlanName string
param appServiceKind string

resource appServicePlan 'Microsoft.Web/sites@2023-01-01' = {
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
