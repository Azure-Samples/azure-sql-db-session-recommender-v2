targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Identity
@description('Id of the user or app to assign application roles')
param principalId string

// OpenAI
param openAIServiceName string = ''
param openAISkuName string = 'S0'
param embeddingDeploymentName string = 'embeddings'
param gptDeploymentName string = 'gpt'

// Azure SQL
@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string
@secure()
@description('Application user password')
param appUserPassword string
param dbServiceName string = ''
param dbName string = 'session_recommender_v2'

param keyVaultName string = ''

param storageAccountName string = ''

param functionAppName string = ''

param hostingPlanName string = ''
param staticWebAppName string = ''

param applicationInsightsName string = ''

param logAnalyticsName string = ''

@description('Flag to Use keyvault to store and use keys')
param useKeyVault bool = true

param myTags object = {}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = union({ 'azd-env-name': environmentName }, myTags)
var rgName = 'rg-${environmentName}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

module openAI 'app/openai.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    name: !empty(openAIServiceName) ? openAIServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: openAISkuName
    }
    deployments: [
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: 'text-embedding-ada-002'
        }
        capacity: 30
      }
      {
        name: gptDeploymentName
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo'
        }
        capacity: 120
      }
    ]
    keyVaultName: keyVault.outputs.name
    useKeyVault: useKeyVault
  }
}

module database 'app/sqlserver.bicep' = {
  name: 'database'
  scope: rg
  params: {
    tags: tags
    location: location
    appUserPassword: appUserPassword
    sqlAdminPassword: sqlAdminPassword
    databaseName: dbName
    name: !empty(dbServiceName) ? dbServiceName : '${abbrs.sqlServers}catalog-${resourceToken}'
    openAIEndpoint: openAI.outputs.endpoint
    openAIServiceName: openAI.outputs.name
    openAIDeploymentName: embeddingDeploymentName
    principalId: principalId
  }
}

module keyVault 'core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module hostingPlan 'core/host/appserviceplan.bicep' = {
  name: 'hostingPlan'
  scope: rg
  params: {
    tags: tags
    location: location
    name: !empty(hostingPlanName) ? hostingPlanName : '${abbrs.webServerFarms}${resourceToken}'
    sku: {
      name: 'B1'
    }
    kind: 'linux'
  }
}

module logAnalytics 'core/monitor/loganalytics.bicep' ={
  name: 'logAnalytics'
  scope: rg
  params: {
    name: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.insightsComponents}${resourceToken}'
    location: location
  }
}

module applicationInsights 'core/monitor/applicationinsights.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    name: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

module functionApp 'app/functions.bicep' = {
  name: 'function'
  scope: rg
  params: {
    tags: union(tags, { 'azd-service-name': 'functionapp' })
    location: location
    storageAccountName: storageAccount.outputs.name
    openAIKeyName: useKeyVault ? openAI.outputs.openAIKeyName : ''
    functionAppName: !empty(functionAppName) ? functionAppName : '${abbrs.webSitesFunctions}${resourceToken}'
    hostingPlanId: hostingPlan.outputs.id
    sqlConnectionString: '${database.outputs.connectionString}; Password=${appUserPassword}'
    openAIEmebddingDeploymentName: embeddingDeploymentName
    openAIGPTDeploymentName: gptDeploymentName
    openAIEndpoint: openAI.outputs.endpoint
    keyVaultName: keyVault.outputs.name
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    useKeyVault: useKeyVault
    openAIName: openAI.outputs.name
    keyVaultEndpoint: keyVault.outputs.endpoint
  }
}

module storageAccount 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    tags: tags
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
  }
}

module funcaccess './core/security/keyvault-access.bicep' = if (useKeyVault) {
  name: 'web-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: functionApp.outputs.identityPrincipalId
  }
}

module web 'app/staticwebapp.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(staticWebAppName) ? staticWebAppName : '${abbrs.webStaticSites}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    sqlConnectionString: '${database.outputs.connectionString}; Password=${appUserPassword}'
    sqlServerId: database.outputs.id
    sqlServerLocation: location
    apiResourceId: functionApp.outputs.functionAppResourceId
  }
}

output AZURE_SQL_SQLSERVICE_CONNECTION_STRING_KEY string = database.outputs.connectionStringKey
output AZURE_FUNCTIONAPP_NAME string = functionApp.outputs.name
output AZURE_FUNCTIONAPP_ID string = functionApp.outputs.functionAppResourceId
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VALUT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_STORAGE_NAME string = storageAccount.outputs.name
output AZURE_STATIC_WEB_URL string = web.outputs.uri
output LOG_ANALYTICS_ID string = logAnalytics.outputs.id
output USE_KEY_VAULT bool = useKeyVault
