metadata name = 'DocumentDB Database Account Cassandra Keyspaces Views'
metadata description = 'This module deploys a Cassandra View (Materialized View) within a Cassandra Keyspace in a CosmosDB Account.'

@description('Required. Name of the Cassandra view.')
param name string

@description('Optional. Tags of the Cassandra view resource.')
param tags object?

@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Conditional. The name of the parent Cassandra Keyspace. Required if the template is used in a standalone deployment.')
param cassandraKeyspaceName string

@description('Required. View definition of the Cassandra view. This is the CQL statement that defines the materialized view.')
param viewDefinition string

@description('Optional. Request units per second. Cannot be used with autoscaleSettingsMaxThroughput.')
param throughput int?

@description('Optional. Maximum autoscale throughput for the view. Cannot be used with throughput.')
param autoscaleSettingsMaxThroughput int?

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' existing = {
  name: databaseAccountName

  resource cassandraKeyspace 'cassandraKeyspaces@2025-05-01-preview' existing = {
    name: cassandraKeyspaceName
  }
}

var viewOptions = contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' })
  ? {}
  : {
      autoscaleSettings: throughput == null && autoscaleSettingsMaxThroughput != null
        ? {
            maxThroughput: autoscaleSettingsMaxThroughput
          }
        : null
      throughput: throughput
    }

resource cassandraView 'Microsoft.DocumentDB/databaseAccounts/cassandraKeyspaces/views@2025-05-01-preview' = {
  name: name
  tags: tags
  location: location
  parent: databaseAccount::cassandraKeyspace
  properties: {
    resource: {
      id: name
      viewDefinition: viewDefinition
    }
    options: viewOptions
  }
}

#disable-next-line no-deployments-resources
resource telemetry 'Microsoft.Resources/deployments@2025-04-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.doctdb-dbacct-cassandrakeyspaceview.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://aka.ms/avm/TelemetryInfo'
        }
      }
    }
  }
}

@description('The name of the Cassandra view.')
output name string = cassandraView.name

@description('The resource ID of the Cassandra view.')
output resourceId string = cassandraView.id

@description('The name of the resource group the Cassandra view was created in.')
output resourceGroupName string = resourceGroup().name
