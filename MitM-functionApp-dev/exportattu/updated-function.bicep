param name string 
param serverFarmId string
param tags object = {resource:name}
param location string = resourceGroup().location

resource site 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverFarmId
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: site
  name: 'ftp'
  properties: {
    allow: true
  }
}

resource scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: site
  name: 'scm'
  properties: {
    allow: true
  }
}

resource web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: site
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$fa-demo-20240308-dev'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    managedServiceIdentityId: 26471
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
        description: 'Deny all access'
      }
    ]
    scmIpSecurityRestrictionsDefaultAction: 'Deny'
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'Disabled'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 200
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

resource dnslookup_function 'Microsoft.Web/sites/functions@2023-01-01' = {
  parent: site
  name: 'dnslookup'
  properties: {
    script_root_path_href: 'namehttps://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/'
    script_href: 'namehttps://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/run.csx'
    config_href: 'namehttps://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/function.json'
    test_data_href: 'namehttps://${name}.azurewebsites.net/admin/vfs/data/Functions/sampledata/dnslookup.dat'
    href: 'namehttps://${name}.azurewebsites.net/admin/functions/dnslookup'
    config: {}
    test_data: '{\r\n    "name": "Azure"\r\n}'
    invoke_url_template: 'namehttps://${name}.azurewebsites.net/api/dnslookup'
    language: 'CSharp'
    isDisabled: false
  }
}

resource azurewebsites 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: site
  name: '${name}.azurewebsites.net'
  properties: {
    siteName: name
    hostNameType: 'Verified'
  }
}
