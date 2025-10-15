metadata name = 'DocumentDB Database Account Cassandra Role Definitions.'
metadata description = 'This module deploys a Cassandra Role Definition in a CosmosDB Account.'

@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Optional. The unique identifier of the Role Definition.')
param name string?

@description('Required. A user-friendly name for the Role Definition. Must be unique for the database account.')
param roleName string

@description('Optional. An array of data actions that are allowed.')
param dataActions string[] = []

@description('Optional. An array of data actions that are denied.')
param notDataActions string[] = []

@description('Optional. A set of fully qualified Scopes at or below which Role Assignments may be created using this Role Definition. This will allow application of this Role Definition on the entire database account or any underlying Database / Keyspace. Must have at least one element. Scopes higher than Database account are not enforceable as assignable Scopes. Note that resources referenced in assignable Scopes need not exist. Defaults to the current account.')
param assignableScopes string[]?

@description('Optional. An array of Cassandra Role Assignments to be created for the Cassandra Role Definition.')
param cassandraRoleAssignments cassandraRoleAssignmentType[]?

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

var enableReferencedModulesTelemetry = false

// ============== //
// Resources      //
// ============== //

#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.doctdb-dbacct-cassandraroledefinition.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name), 0, 4)}'
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

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: databaseAccountName
}

resource cassandraRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/cassandraRoleDefinitions@2025-05-01-preview' = {
  parent: databaseAccount
  name: name ?? guid(databaseAccount.id, databaseAccountName, 'cassandra-role')
  properties: {
    assignableScopes: assignableScopes ?? [
      databaseAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
        notDataActions: notDataActions
      }
    ]
    roleName: roleName
    type: 'CustomRole'
  }
}

module databaseAccount_cassandraRoleAssignments '../cassandra-role-assignment/main.bicep' = [
  for (cassandraRoleAssignment, index) in (cassandraRoleAssignments ?? []): {
    name: '${uniqueString(deployment().name)}-cassandra-ra-${index}'
    params: {
      databaseAccountName: databaseAccount.name
      roleDefinitionId: cassandraRoleDefinition.id
      principalId: cassandraRoleAssignment.principalId
      name: cassandraRoleAssignment.?name
      scope: cassandraRoleAssignment.?scope
      enableTelemetry: enableReferencedModulesTelemetry
    }
  }
]

// ============ //
// Outputs      //
// ============ //

@description('The name of the cassandra role definition.')
output name string = cassandraRoleDefinition.name

@description('The resource ID of the cassandra role definition.')
output resourceId string = cassandraRoleDefinition.id

@description('The name of the resource group the cassandra role definition was created in.')
output resourceGroupName string = resourceGroup().name

// =============== //
//   Definitions   //
// =============== //

@export()
type cassandraRoleAssignmentType = {
  @description('Optional. The unique identifier of the role assignment.')
  name: string?

  @description('Required. The unique identifier for the associated AAD principal.')
  principalId: string

  @description('Optional. The data plane resource path for which access is being granted. Defaults to the current account.')
  scope: string?
}
