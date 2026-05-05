targetScope = 'resourceGroup'

// ============================================================================
// Scaling Plan - Azure Virtual Desktop
// Module: avm/res/desktop-virtualization/scaling-plan
// Supports both simple (WAF-aligned defaults) and full large parameter set
// deployments. All advanced parameters are optional with sensible defaults.
// ============================================================================

@sys.description('Required. Name of the Scaling Plan.')
param name string

@sys.description('Optional. Location for the Scaling Plan. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Optional. Friendly name of the Scaling Plan.')
param friendlyName string = name

@sys.description('Optional. Description of the Scaling Plan.')
param description string = ''

@sys.description('Optional. Time zone for schedule evaluation. Use IANA or Windows time zone names.')
param timeZone string = 'Eastern Standard Time'

@sys.description('Optional. Host Pool type this Scaling Plan targets.')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Pooled'

@sys.description('Optional. List of Host Pool references to associate with this Scaling Plan.')
param hostPoolReferences array = []

@sys.description('Optional. Scaling schedules defining ramp-up, peak, ramp-down, and off-peak phases.')
param schedules array = []

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

@sys.description('Optional. Array of role assignments to apply to the Scaling Plan.')
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

module scalingPlan 'br/public:avm/res/desktop-virtualization/scaling-plan:0.5.0' = {
  name: '${uniqueString(deployment().name, location)}-scalingPlan'
  params: {
    name: name
    location: location
    friendlyName: friendlyName
    description: description
    timeZone: timeZone
    hostPoolType: hostPoolType
    hostPoolReferences: !empty(hostPoolReferences) ? hostPoolReferences : null
    schedules: !empty(schedules) ? schedules : null
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

@sys.description('The resource ID of the deployed Scaling Plan.')
output resourceId string = scalingPlan.outputs.resourceId

@sys.description('The name of the deployed Scaling Plan.')
output name string = scalingPlan.outputs.name

@sys.description('The location of the deployed Scaling Plan.')
output location string = scalingPlan.outputs.location

@sys.description('The resource group name where the Scaling Plan was deployed.')
output resourceGroupName string = scalingPlan.outputs.resourceGroupName
