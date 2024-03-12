metadata description = 'Creates an Azure Static Web Apps instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
param sku object = {
  name: 'Standard'
  tier: 'Standard'
}
param sqlServerLocation string
param sqlServerId string
@secure()
param sqlConnectionString string
param apiResourceId string

resource web 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
  sku: sku
  resource apifunc 'linkedBackends@2022-09-01' = {
    name: 'default'
    properties: {
      backendResourceId: apiResourceId
      region: location
    }
  }
  resource dbconn 'databaseConnections@2022-09-01' = {
    name: 'default'
    properties: {
      connectionString: sqlConnectionString
      region: sqlServerLocation
      resourceId: sqlServerId      
    }
  }
}

output name string = web.name
output uri string = 'https://${web.properties.defaultHostname}'
