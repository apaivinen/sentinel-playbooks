using './main.bicep'

param resourceGroupName = ''
param servicePrefix = 'Anssi'
param deploymentEnvironment = 'dev'
param name = 'MitM'
param location = ''
param tags = {
  resource: name
}

