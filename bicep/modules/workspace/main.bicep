targetScope = 'resourceGroup'

// ============================================================================
// Workspace - Azure Virtual Desktop
// Module: avm/res/desktop-virtualization/workspace
// Supports both simple (WAF-aligned defaults) and full large parameter set
// deployments. All advanced parameters are optional with sensible defaults.
// ============================================================================

@sys.description('Required. Name of the AVD Workspace.')
param name string

@sys.description('Optional. Location for the Workspace. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Optional. Friendly name of the Workspace.')
param friendlyName string = name

@sys.description('Optional. Description of the Workspace.')
param description string = ''

@sys.description('Optional. List of Application Group resource IDs to register with this Workspace.')
param applicationGroupReferences array = []

@sys.description('Optional. Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
  'EnabledForClientsOnly'
  'EnabledForSessionHostsOnly'
])
param publicNetworkAccess string = 'Enabled'

// ── Diagnostics ─────────────────────────────────────────────────────────────

@sys.description('Optional. Full diagnosticSettings array passed directly to the AVM module. When provided, takes precedence over logAnalyticsWorkspaceResourceId.')
param diagnosticSettings array = []

@sys.description('Optional. Resource ID of a Log Analytics Workspace. Used to build a simple allLogs diagnostic setting when diagnosticSettings is not provided.')
param logAnalyticsWorkspaceResourceId string = ''

// ── Governance ───────────────────────────────────────────────────────────────

@sys.description('Optional. Resource lock configuration. Defaults to CanNotDelete. Pass an empty object {} to disable locking.')
param lock object = {
  kind: 'CanNotDelete'
}

@sys.description('Optional. Array of role assignments to apply to the Workspace.')
param roleAssignments array = []

// ── Networking ───────────────────────────────────────────────────────────────

@sys.description('Optional. Private endpoint configurations for the Workspace. Supported services: feed, global.')
param privateEndpoints array = []

// ── Telemetry ────────────────────────────────────────────────────────────────

@sys.description('Optional. Enable or disable AVM telemetry for this module.')
param enableTelemetry bool = true

@sys.description('Optional. Tags for all deployed resources.')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

var resolvedDiagnosticSettings = !empty(diagnosticSettings)
  ? diagnosticSettings
  : (!empty(logAnalyticsWorkspaceResourceId)
      ? [
          {
            workspaceResourceId: logAnalyticsWorkspaceResourceId
            logCategoriesAndGroups: [
              {
                categoryGroup: 'allLogs'
              }
            ]
          }
        ]
      : [])

// ============================================================================
// Module Deployment
// ============================================================================

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.1' = {
  name: '${uniqueString(deployment().name, location)}-workspace'
  params: {
    name: name
    location: location
    friendlyName: friendlyName
    description: description
    applicationGroupReferences: !empty(applicationGroupReferences) ? applicationGroupReferences : null
    publicNetworkAccess: publicNetworkAccess
    diagnosticSettings: resolvedDiagnosticSettings
    lock: !empty(lock) ? lock : null
    roleAssignments: !empty(roleAssignments) ? roleAssignments : null
    privateEndpoints: !empty(privateEndpoints) ? privateEndpoints : null
    enableTelemetry: enableTelemetry
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

@sys.description('The resource ID of the deployed Workspace.')
output resourceId string = workspace.outputs.resourceId

@sys.description('The name of the deployed Workspace.')
output name string = workspace.outputs.name

@sys.description('The location of the deployed Workspace.')
output location string = workspace.outputs.location

@sys.description('The resource group name where the Workspace was deployed.')
output resourceGroupName string = workspace.outputs.resourceGroupName
