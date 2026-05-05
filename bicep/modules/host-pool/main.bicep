targetScope = 'resourceGroup'

// ============================================================================
// Host Pool - Azure Virtual Desktop
// Deploys a DesktopVirtualization/hostPools resource directly via the ARM API.
// Supports an optional registrationInfo parameter to generate a host pool
// registration token at deploy time; the token is available via the
// registrationToken output and is marked @secure() so it is not stored in
// ARM deployment history.
// ============================================================================

@sys.description('Required. Name of the Host Pool.')
param name string

@sys.description('Optional. Location for the Host Pool. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Optional. Friendly name of the Host Pool.')
param friendlyName string = name

@sys.description('Optional. Description of the Host Pool.')
param description string = ''

@sys.description('Optional. Host Pool type. Pooled for shared, Personal for persistent desktops.')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Pooled'

@sys.description('Optional. Load balancer algorithm. BreadthFirst spreads users, DepthFirst fills hosts first.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@sys.description('Optional. Maximum number of sessions per session host.')
param maxSessionLimit int = 10

@sys.description('Optional. Preferred application group type.')
@allowed([
  'Desktop'
  'None'
  'RailApplications'
])
param preferredAppGroupType string = 'Desktop'

@sys.description('Optional. Allow users to start a session host VM from a deallocated state.')
param startVMOnConnect bool = true

@sys.description('Optional. Enable validation environment for testing new features.')
param validationEnvironment bool = false

@sys.description('Optional. Custom RDP properties for the Host Pool.')
param customRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;'

@sys.description('Optional. Controls whether public network access is allowed for the Host Pool. Allowed: Enabled, Disabled.')
param publicNetworkAccess string = 'Enabled'

@sys.description('Optional. Personal desktop assignment type for Personal host pools. Allowed: Automatic, Direct.')
param personalDesktopAssignmentType string = ''

@sys.description('Optional. VM template configuration used when provisioning session hosts via the portal.')
param vmTemplate object = {}

@sys.description('Optional. Agent update configuration specifying scheduled maintenance windows for session host agents.')
param agentUpdate object = {}

// ── Diagnostics ─────────────────────────────────────────────────────────────

@sys.description('Optional. Resource ID of a Log Analytics Workspace for diagnostics.')
param logAnalyticsWorkspaceResourceId string = ''

// ── Governance ───────────────────────────────────────────────────────────────

@sys.description('Optional. Resource lock configuration. Defaults to CanNotDelete. Pass an empty object {} to disable locking.')
param lock object = {
  kind: 'CanNotDelete'
}

// ── Tags ─────────────────────────────────────────────────────────────────────

@sys.description('Optional. Tags for all deployed resources.')
param tags object = {}

// ── Registration ─────────────────────────────────────────────────────────────

@sys.description('Optional. Registration info to generate a host pool registration token at deploy time. Pass { expirationTime: "<ISO8601 datetime>", registrationTokenOperation: "Update" } to create a new token. The generated token is available via the registrationToken output.')
param registrationInfo object = {}

// ============================================================================
// Host Pool Resource
// ============================================================================

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-09-09' = {
  name: name
  location: location
  tags: tags
  properties: {
    friendlyName: friendlyName
    description: description
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    preferredAppGroupType: preferredAppGroupType
    startVMOnConnect: startVMOnConnect
    validationEnvironment: validationEnvironment
    customRdpProperty: customRdpProperty
    // publicNetworkAccess is a valid runtime property but absent from the 2022-09-09 Bicep type
    // definition (type inaccuracy). Suppress the spurious BCP037 warning.
    #disable-next-line BCP037
    publicNetworkAccess: publicNetworkAccess
    personalDesktopAssignmentType: !empty(personalDesktopAssignmentType)
      ? personalDesktopAssignmentType
      : null
    vmTemplate: !empty(vmTemplate) ? string(vmTemplate) : null
    agentUpdate: !empty(agentUpdate) ? agentUpdate : null
    registrationInfo: !empty(registrationInfo) ? registrationInfo : null
  }
}

// ── Diagnostics ──────────────────────────────────────────────────────────────

// Note: Microsoft.Insights/diagnosticSettings has no non-preview stable GA version;
// '2021-05-01-preview' is the current recommended version (used by AVM modules and Azure docs).
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceResourceId)) {
  name: '${name}-diagnostics'
  scope: hostPool
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

// ── Resource lock ─────────────────────────────────────────────────────────────

resource hostPoolLock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${name}-lock'
  scope: hostPool
  properties: {
    level: lock.kind
    notes: lock.?notes
  }
}

// ============================================================================
// Outputs
// ============================================================================

@sys.description('The resource ID of the deployed Host Pool.')
output resourceId string = hostPool.id

@sys.description('The name of the deployed Host Pool.')
output name string = hostPool.name

@sys.description('The location of the deployed Host Pool.')
output location string = hostPool.location

@sys.description('The resource group name where the Host Pool was deployed.')
output resourceGroupName string = resourceGroup().name

@secure()
@sys.description('The registration token for the host pool. Only populated when registrationInfo was provided with registrationTokenOperation=Update. Marked @secure() so the value is not stored in deployment history.')
output registrationToken string = !empty(registrationInfo)
  ? (hostPool.properties.?registrationInfo.?token ?? '')
  : ''
