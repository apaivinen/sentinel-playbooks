param appName string = 'resolve-domain'
param serverfarms_ASP_RGTenantSentinelPlaybooks_b6ad_externalid string = '/subscriptions/d781400b-6ce7-4b68-aaf2-6b71a353b7fc/resourceGroups/RG-TenantSentinel-Playbooks/providers/Microsoft.Web/serverfarms/ASP-RGTenantSentinelPlaybooks-b6ad'

resource appName_resource 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: 'West Europe'
  tags: {
    resource: 'resolve-domain'
  }
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${appName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${appName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_ASP_RGTenantSentinelPlaybooks_b6ad_externalid
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
      http20Enabled: true
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
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource appName_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appName_resource
  name: 'ftp'
  location: 'West Europe'
  tags: {
    resource: 'resolve-domain'
  }
  properties: {
    allow: false
  }
}

resource appName_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appName_resource
  name: 'scm'
  location: 'West Europe'
  tags: {
    resource: 'resolve-domain'
  }
  properties: {
    allow: false
  }
}

resource appName_web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appName_resource
  name: 'web'
  location: 'West Europe'
  tags: {
    resource: 'resolve-domain'
  }
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
    netFrameworkVersion: 'v6.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$resolve-domain'
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
    publicNetworkAccess: 'Enabled'
    cors: {
      allowedOrigins: ['https://portal.azure.com']
      supportCredentials: false
    }
    localMySqlEnabled: false
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
        ipAddress: '88.86.150.114/32'
        action: 'Allow'
        tag: 'Default'
        priority: 300
        name: 'anssi-ip'
        description: 'anssi'
      }
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
    http20Enabled: true
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

resource appName_Resolve 'Microsoft.Web/sites/functions@2023-01-01' = {
  parent: appName_resource
  name: 'Resolve'
  location: 'West Europe'
  properties: {
    script_root_path_href: 'https://resolve-domain.azurewebsites.net/admin/vfs/site/wwwroot/Resolve/'
    script_href: 'https://resolve-domain.azurewebsites.net/admin/vfs/site/wwwroot/Resolve/run.csx'
    config_href: 'https://resolve-domain.azurewebsites.net/admin/vfs/site/wwwroot/Resolve/function.json'
    test_data_href: 'https://resolve-domain.azurewebsites.net/admin/vfs/data/Functions/sampledata/Resolve.dat'
    href: 'https://resolve-domain.azurewebsites.net/admin/functions/Resolve'
    config: {}
    test_data: '{"method":"post","queryStringParams":[],"headers":[],"body":"{\\"url\\":\\"https://login.leikkikentta.fi\\"}"}'
    invoke_url_template: 'https://resolve-domain.azurewebsites.net/api/resolve'
    language: 'CSharp'
    isDisabled: false
  }
}

resource appName_appName_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: appName_resource
  name: '${appName}.azurewebsites.net'
  location: 'West Europe'
  properties: {
    siteName: 'resolve-domain'
    hostNameType: 'Verified'
  }
}
