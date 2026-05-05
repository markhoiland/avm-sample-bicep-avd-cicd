targetScope = 'resourceGroup'

// ============================================================================
// Application Group - Azure Virtual Desktop
// Module: avm/res/desktop-virtualization/application-group
// Supports both simple (WAF-aligned defaults) and full large parameter set
// deployments. All advanced parameters are optional with sensible defaults.
// ============================================================================

@sys.description('Required. Name of the Application Group.')
@minLength(3)
param name string

@sys.description('Optional. Location for the Application Group. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Required. The type of Application Group. Desktop for full desktop, RemoteApp for individual apps.')
@allowed([
  'Desktop'
  'RemoteApp'
])
param applicationGroupType string

@sys.description('Required. Name of the existing Host Pool to associate with this Application Group.')
param hostpoolName string

@sys.description('Optional. Friendly name of the Application Group.')
param friendlyName string = name

@sys.description('Optional. Description of the Application Group.')
param description string = ''

@sys.description('Optional. Show the Application Group in the AVD feed.')
param showInFeed bool = true

@sys.description('Optional. RemoteApp applications to publish in this Application Group. Only applicable when applicationGroupType is RemoteApp.')
param applications array = []

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

@sys.description('Optional. Array of role assignments to apply to the Application Group.')
param roleAssignments array = []

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

module applicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = {
  name: '${uniqueString(deployment().name, location)}-appGroup'
  params: {
    name: name
    location: location
    applicationGroupType: applicationGroupType
    hostpoolName: hostpoolName
    friendlyName: friendlyName
    description: description
    showInFeed: showInFeed
    applications: !empty(applications) ? applications : null
    diagnosticSettings: resolvedDiagnosticSettings
    lock: !empty(lock) ? lock : null
    roleAssignments: !empty(roleAssignments) ? roleAssignments : null
    enableTelemetry: enableTelemetry
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

@sys.description('The resource ID of the deployed Application Group.')
output resourceId string = applicationGroup.outputs.resourceId

@sys.description('The name of the deployed Application Group.')
output name string = applicationGroup.outputs.name

@sys.description('The location of the deployed Application Group.')
output location string = applicationGroup.outputs.location

@sys.description('The resource group name where the Application Group was deployed.')
output resourceGroupName string = applicationGroup.outputs.resourceGroupName
