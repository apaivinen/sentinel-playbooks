param name string = 'fa-demo-20240308-dev'
param serverfarms_fa_demo_20240308_dev_externalid string = '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/resourceGroups/RG-Sentinel-Playbooks/providers/Microsoft.Web/serverfarms/fa-demo-20240308-dev'
param tags object = {resource:name}
param location string = resourceGroup().location

resource site 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp'
  dependsOn": [
    "[resourceId('Microsoft.Web/serverfarms', parameters('hostingPlanName'))]"
  ]
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
    serverFarmId: serverfarms_fa_demo_20240308_dev_externalid
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
    customDomainVerificationId: '64901437E33A0ADCFC5B020E11D31552AE453D38E015EB4B1F97239A5078B2EF'
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
  location: location
  tags: tags
  properties: {
    allow: true
  }
}

resource scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: site
  name: 'scm'
  location: location
  tags: tags
  properties: {
    allow: true
  }
}

resource web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: site
  name: 'web'
  location: location
  tags: tags
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
  location: location
  properties: {
    script_root_path_href: 'https://fa-demo-20240308-dev.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/'
    script_href: 'https://fa-demo-20240308-dev.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/run.csx'
    config_href: 'https://fa-demo-20240308-dev.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/function.json'
    test_data_href: 'https://fa-demo-20240308-dev.azurewebsites.net/admin/vfs/data/Functions/sampledata/dnslookup.dat'
    href: 'https://fa-demo-20240308-dev.azurewebsites.net/admin/functions/dnslookup'
    config: {}
    test_data: '{\r\n    "name": "Azure"\r\n}'
    invoke_url_template: 'https://fa-demo-20240308-dev.azurewebsites.net/api/dnslookup'
    language: 'CSharp'
    isDisabled: false
  }
}

resource sites_fa_demo_20240308_dev_name_sites_fa_demo_20240308_dev_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: site
  name: '${name}.azurewebsites.net'
  location: location
  properties: {
    siteName: 'fa-demo-20240308-dev'
    hostNameType: 'Verified'
  }
}
