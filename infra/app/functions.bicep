param functionAppName string
param location string = resourceGroup().location
param hostingPlanId string
param storageAccountName string
@secure()
param sqlConnectionString string
param keyVaultName string
param tags object = {}
param applicationInsightsConnectionString string
param useKeyVault bool
param keyVaultEndpoint string = ''
@secure()
param openAIEndpoint string
param openAIKeyName string
param openAIName string
param openAIEmebddingDeploymentName string = 'embeddings'
param openAIGPTDeploymentName string = 'gpt'

module functionApp '../core/host/functions.bicep' = {
  name: 'function1'
  params: {
    location: location
    alwaysOn: false
    tags: union(tags, { 'azd-service-name': 'functionapp' })
    kind: 'functionapp'
    keyVaultName: keyVaultName
    appServicePlanId: hostingPlanId
    name: functionAppName
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    storageAccountName: storageAccountName
    appSettings: {
      WEBSITE_CONTENTSHARE: toLower(functionAppName)
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName), '2022-05-01').keys[0].value}'
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
      AZURE_SQL_CONNECTION_STRING: sqlConnectionString
      AZURE_OPENAI_ENDPOINT: openAIEndpoint
      AZURE_OPENAI_KEY: useKeyVault ? openAIKeyName : listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.CognitiveServices/accounts', openAIName), '2023-05-01').key1
      AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT_NAME: openAIEmebddingDeploymentName
      AZURE_OPENAI_GPT_DEPLOYMENT_NAME: openAIGPTDeploymentName      
      AZURE_KEY_VAULT_ENDPOINT: useKeyVault ? keyVaultEndpoint : ''
    }
  }
}

output functionAppResourceId string = functionApp.outputs.functionAppResourceId
output name string = functionApp.outputs.name
output uri string = functionApp.outputs.uri
output identityPrincipalId string = functionApp.outputs.identityPrincipalId
