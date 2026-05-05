targetScope = 'subscription'

// ============================================================================
// Platform Orchestration - Azure Virtual Desktop
// Deploys resource group + AVD modules in dependency order from subscription scope.
// ============================================================================

@description('Optional. Deployment timestamp used to compute the host pool registration token expiry (token valid for 2 hours from deployment time). Populated automatically by ARM -- do not set this manually.')
param deploymentTime string = utcNow()

@description('Required. Name of the resource group that contains all AVD resources.')
param resourceGroupName string

@description('Required. Azure region for the resource group and module deployments.')
param resourceGroupLocation string

@description('Optional. Tags applied to the resource group and merged into module tags.')
param globalTags object = {}

// Host Pool
@description('Required. Name of the Host Pool. For example: vdpool-avd-prod-001.')
param hostPoolName string

@description('Optional. Friendly name of the Host Pool.')
param hostPoolFriendlyName string = 'AVD Production Host Pool'

@description('Optional. Description of the Host Pool.')
param hostPoolDescription string = 'Pooled host pool for AVD production environment (WAF-aligned).'

@allowed([
  'Pooled'
  'Personal'
])
@description('Optional. Host Pool type.')
param hostPoolType string = 'Pooled'

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
@description('Optional. Load balancer algorithm.')
param hostPoolLoadBalancerType string = 'BreadthFirst'

@description('Optional. Maximum number of sessions per session host VM.')
param hostPoolMaxSessionLimit int = 10

@allowed([
  'Desktop'
  'None'
  'RailApplications'
])
@description('Optional. Preferred application group type for the Host Pool.')
param hostPoolPreferredAppGroupType string = 'Desktop'

@description('Optional. Allow users to power on deallocated session hosts at sign-in.')
param hostPoolStartVMOnConnect bool = true

@description('Optional. Enable Host Pool validation environment.')
param hostPoolValidationEnvironment bool = false

@description('Optional. Custom RDP properties string for the Host Pool.')
param hostPoolCustomRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;'

@description('Optional. Log Analytics workspace resource ID for Host Pool diagnostics.')
param hostPoolLogAnalyticsWorkspaceResourceId string = ''

@description('Optional. Additional tags for Host Pool resources.')
param hostPoolTags object = {}

// Application Group
@description('Required. Name of the Application Group. For example: vdag-avd-prod-001.')
param applicationGroupName string

@allowed([
  'Desktop'
  'RemoteApp'
])
@description('Required. Application Group type.')
param applicationGroupType string = 'Desktop'

@description('Optional. Friendly name of the Application Group.')
param applicationGroupFriendlyName string = 'AVD Production Desktop'

@description('Optional. Description of the Application Group.')
param applicationGroupDescription string = 'Desktop Application Group for AVD production environment (WAF-aligned).'

@description('Optional. Show the Application Group in users\' AVD feed.')
param applicationGroupShowInFeed bool = true

@description('Optional. Log Analytics workspace resource ID for Application Group diagnostics.')
param applicationGroupLogAnalyticsWorkspaceResourceId string = ''

@description('Optional. Object ID of the user or group to assign the "Desktop Virtualization User" role on the Application Group. Leave empty to skip the role assignment.')
param applicationGroupPrincipalId string = ''

@description('Optional. Principal type for the Application Group role assignment (User, Group, ServicePrincipal, or Device).')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'Device'
])
param applicationGroupPrincipalType string = 'Group'

@description('Optional. Additional tags for Application Group resources.')
param applicationGroupTags object = {}

// Workspace
@description('Required. Name of the Workspace. For example: vdws-avd-prod-001.')
param workspaceName string

@description('Optional. Friendly name of the Workspace.')
param workspaceFriendlyName string = 'AVD Production Workspace'

@description('Optional. Description of the Workspace.')
param workspaceDescription string = 'AVD Workspace for production environment (WAF-aligned).'

@allowed([
  'Enabled'
  'Disabled'
  'EnabledForClientsOnly'
  'EnabledForSessionHostsOnly'
])
@description('Optional. Public network access mode for Workspace.')
param workspacePublicNetworkAccess string = 'Enabled'

@description('Optional. Extra Application Group resource IDs to register with this Workspace.')
param workspaceAdditionalApplicationGroupReferences array = []

@description('Optional. Log Analytics workspace resource ID for Workspace diagnostics.')
param workspaceLogAnalyticsWorkspaceResourceId string = ''

@description('Optional. Additional tags for Workspace resources.')
param workspaceTags object = {}

// Scaling Plan
@description('Required. Name of the Scaling Plan. For example: vdscaling-avd-prod-001.')
param scalingPlanName string

@description('Optional. Friendly name of the Scaling Plan.')
param scalingPlanFriendlyName string = 'AVD Production Scaling Plan'

@description('Optional. Description of the Scaling Plan.')
param scalingPlanDescription string = 'Scaling Plan for AVD production host pool (WAF-aligned).'

@description('Optional. Time zone name used for schedule evaluation.')
param scalingPlanTimeZone string = 'Eastern Standard Time'

@allowed([
  'Pooled'
  'Personal'
])
@description('Optional. Host Pool type targeted by the Scaling Plan.')
param scalingPlanHostPoolType string = 'Pooled'

@description('Optional. Scaling schedules for the plan.')
param scalingPlanSchedules array = [
  {
    name: 'Weekday-Schedule'
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    rampUpStartTime: {
      hour: 7
      minute: 0
    }
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60
    peakStartTime: {
      hour: 9
      minute: 0
    }
    peakLoadBalancingAlgorithm: 'BreadthFirst'
    rampDownStartTime: {
      hour: 17
      minute: 0
    }
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 10
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: false
    rampDownWaitTimeMinutes: 30
    rampDownNotificationMessage: 'You will be logged off in 30 minutes. Please save your work.'
    rampDownStopHostsWhen: 'ZeroSessions'
    offPeakStartTime: {
      hour: 20
      minute: 0
    }
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
  }
]

@description('Optional. Log Analytics workspace resource ID for Scaling Plan diagnostics.')
param scalingPlanLogAnalyticsWorkspaceResourceId string = ''

@description('Optional. Additional tags for Scaling Plan resources.')
param scalingPlanTags object = {}

// Virtual Network
@description('Optional. Deploy an Azure Virtual Network with AVD session hosts subnet.')
param deployVirtualNetwork bool = false

@description('Optional. Name of the Virtual Network to create. Required when deployVirtualNetwork is true.')
param vnetName string = ''

@description('Optional. Address prefix for the Virtual Network (e.g., "10.0.0.0/16").')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Optional. Name of the AVD session hosts subnet.')
param avdshSubnetName string = 'snet-avdsh'

@description('Optional. Address prefix for the AVD session hosts subnet (e.g., "10.0.1.0/24").')
param avdshSubnetPrefix string = '10.0.1.0/24'

@description('Optional. Array of additional subnets beyond the AVD session hosts subnet.')
param additionalSubnets array = []

@description('Optional. Log Analytics workspace resource ID for VNet diagnostics.')
param vnetLogAnalyticsWorkspaceResourceId string = ''

@description('Optional. Additional tags for Virtual Network resources.')
param vnetTags object = {}

// Session Hosts
@description('Optional. Enable session host VM deployment.')
param deploySessionHosts bool = false

@description('Optional. Number of session host VMs to deploy.')
@minValue(1)
@maxValue(100)
param sessionHostCount int = 2

@description('Optional. Naming prefix for session host VMs (e.g., "vm-avd-sh"). VMs will be named: {prefix}-001, {prefix}-002, etc.')
param sessionHostNamePrefix string = 'vm-avd-sh'

@description('Optional. VM size for session hosts (e.g., "Standard_D4s_v3").')
param sessionHostVmSize string = 'Standard_D4s_v3'

@description('Optional. Subnet resource ID where session hosts will be deployed. Required when deploySessionHosts is true. When deployVirtualNetwork is true, defaults to the avdsh subnet.')
param sessionHostSubnetResourceId string = ''

@description('Optional. Admin username for session host VMs.')
param sessionHostAdminUsername string = 'azureuser'

@description('Optional. Admin password for session host VMs. Required when deploySessionHosts is true.')
@secure()
param sessionHostAdminPassword string = ''

@description('Optional. Set to true to join session host VMs to Entra ID (Microsoft Entra ID Join).')
param enableSessionHostEntraIdJoin bool = false

@description('Optional. Role assignments applied at resource group scope to enable Entra ID user login on session host VMs (e.g. Virtual Machine User Login or Virtual Machine Administrator Login roles). Only used when enableSessionHostEntraIdJoin is true. Each entry requires principalId and roleDefinitionIdOrName; principalType is optional.')
param sessionHostEntraIdLoginRoleAssignments array = []

@description('Optional. Availability zone for session host VMs (0 = no zone pinning, 1-3 = specific zone).')
@minValue(0)
@maxValue(3)
param sessionHostAvailabilityZone int = 0

@description('Optional. OS image SKU for session host VMs.')
param sessionHostImageSku string = 'win11-22h2-avd'

@description('Optional. OS disk storage account type for session host VMs.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param sessionHostOsDiskType string = 'Premium_LRS'

@description('Optional. Additional tags for session host VMs.')
param sessionHostTags object = {}

// AVD Auto-scaling
@description('Optional. Object ID of the "Windows Virtual Desktop" service principal in this tenant. When provided, grants "Desktop Virtualization Power On Off Contributor" on the resource group so the Scaling Plan can manage session host power state, and associates the Scaling Plan with the host pool. Retrieve via: az ad sp show --id 9cdead84-a844-4324-93f2-b2e6bb768d07 --query id -o tsv. Leave empty to skip the RBAC assignment and host pool association (scaling plan is deployed without autoscale capability until re-deployed with this value).')
param avdServicePrincipalObjectId string = ''

// ============================================================================
// Deployment-time validation for parameters
// These assertions fail the deployment immediately with an actionable error if
// required parameters are missing.
// The assertion name appears in the deployment error, making the failure reason clear.
// ============================================================================

// Fails with: "Assertion 'vnetName_must_be_provided_when_deployVirtualNetwork_is_true' failed"
assert vnetName_must_be_provided_when_deployVirtualNetwork_is_true = !deployVirtualNetwork || !empty(vnetName)
// Fails with: "Assertion 'sessionHostSubnetResourceId_or_deployVirtualNetwork_must_be_provided_when_deploySessionHosts_is_true' failed"
assert sessionHostSubnetResourceId_or_deployVirtualNetwork_must_be_provided_when_deploySessionHosts_is_true = !deploySessionHosts || !empty(sessionHostSubnetResourceId) || deployVirtualNetwork
// Fails with: "Assertion 'sessionHostAdminPassword_must_be_provided_when_deploySessionHosts_is_true' failed"
assert sessionHostAdminPassword_must_be_provided_when_deploySessionHosts_is_true = !deploySessionHosts || !empty(sessionHostAdminPassword)

// Build the Application Group role assignments array from the scalar principal parameters.
// When applicationGroupPrincipalId is empty, no role assignment is created.
var varApplicationGroupRoleAssignments = !empty(applicationGroupPrincipalId)
  ? [
      {
        roleDefinitionIdOrName: 'Desktop Virtualization User'
        principalId: applicationGroupPrincipalId
        principalType: applicationGroupPrincipalType
      }
    ]
  : []

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: globalTags
}

// Grant the Windows Virtual Desktop service principal "Desktop Virtualization Power On Off Contributor"
// on the resource group so the Scaling Plan can start/deallocate session hosts during autoscale.
// Required by AVD autoscale: https://learn.microsoft.com/azure/virtual-desktop/autoscale-scaling-plan
// Only deployed when avdServicePrincipalObjectId is provided; idempotent on repeat runs.
module avdAutoscaleRbac './modules/avd-autoscale-rbac/main.bicep' = if (!empty(avdServicePrincipalObjectId)) {
  name: 'avdAutoscaleRbac-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    avdServicePrincipalObjectId: avdServicePrincipalObjectId
  }
}

module hostPool './modules/host-pool/main.bicep' = {
  name: 'hostPool-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    name: hostPoolName
    location: resourceGroupLocation
    friendlyName: hostPoolFriendlyName
    description: hostPoolDescription
    hostPoolType: hostPoolType
    loadBalancerType: hostPoolLoadBalancerType
    maxSessionLimit: hostPoolMaxSessionLimit
    preferredAppGroupType: hostPoolPreferredAppGroupType
    startVMOnConnect: hostPoolStartVMOnConnect
    validationEnvironment: hostPoolValidationEnvironment
    customRdpProperty: hostPoolCustomRdpProperty
    logAnalyticsWorkspaceResourceId: hostPoolLogAnalyticsWorkspaceResourceId
    registrationInfo: deploySessionHosts
      ? {
          expirationTime: dateTimeAdd(deploymentTime, 'PT2H')
          registrationTokenOperation: 'Update'
        }
      : {}
    tags: union(globalTags, hostPoolTags)
  }
}

module applicationGroup './modules/application-group/main.bicep' = {
  name: 'applicationGroup-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    name: applicationGroupName
    location: resourceGroupLocation
    applicationGroupType: applicationGroupType
    hostpoolName: hostPool.outputs.name
    friendlyName: applicationGroupFriendlyName
    description: applicationGroupDescription
    showInFeed: applicationGroupShowInFeed
    roleAssignments: varApplicationGroupRoleAssignments
    logAnalyticsWorkspaceResourceId: applicationGroupLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, applicationGroupTags)
  }
}

module workspace './modules/workspace/main.bicep' = {
  name: 'workspace-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    name: workspaceName
    location: resourceGroupLocation
    friendlyName: workspaceFriendlyName
    description: workspaceDescription
    applicationGroupReferences: concat([applicationGroup.outputs.resourceId], workspaceAdditionalApplicationGroupReferences)
    publicNetworkAccess: workspacePublicNetworkAccess
    logAnalyticsWorkspaceResourceId: workspaceLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, workspaceTags)
  }
}

module scalingPlan './modules/scaling-plan/main.bicep' = {
  name: 'scalingPlan-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  dependsOn: [avdAutoscaleRbac]
  params: {
    name: scalingPlanName
    location: resourceGroupLocation
    friendlyName: scalingPlanFriendlyName
    description: scalingPlanDescription
    timeZone: scalingPlanTimeZone
    hostPoolType: scalingPlanHostPoolType
    hostPoolReferences: !empty(avdServicePrincipalObjectId)
      ? [
          {
            hostPoolResourceId: hostPool.outputs.resourceId
            scalingPlanEnabled: true
          }
        ]
      : []
    schedules: scalingPlanSchedules
    logAnalyticsWorkspaceResourceId: scalingPlanLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, scalingPlanTags)
  }
}

module vnet './modules/vnet/main.bicep' = if (deployVirtualNetwork) {
  name: 'vnet-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    location: resourceGroupLocation
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    avdshSubnetName: avdshSubnetName
    avdshSubnetPrefix: avdshSubnetPrefix
    additionalSubnets: additionalSubnets
    logAnalyticsWorkspaceResourceId: vnetLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, vnetTags)
  }
}

module sessionHosts './modules/session-hosts/main.bicep' = if (deploySessionHosts) {
  name: 'sessionHosts-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    location: resourceGroupLocation
    hostPoolName: hostPool.outputs.name
    hostPoolRegistrationToken: hostPool.outputs.registrationToken
    subnetResourceId: !empty(sessionHostSubnetResourceId) ? sessionHostSubnetResourceId : (vnet.?outputs.avdshSubnetResourceId ?? '')
    sessionHostCount: sessionHostCount
    sessionHostNamePrefix: sessionHostNamePrefix
    vmSize: sessionHostVmSize
    adminUsername: sessionHostAdminUsername
    adminPassword: sessionHostAdminPassword
    enableEntraIdJoin: enableSessionHostEntraIdJoin
    entraIdLoginRoleAssignments: sessionHostEntraIdLoginRoleAssignments
    availabilityZone: sessionHostAvailabilityZone
    imageSku: sessionHostImageSku
    osDiskType: sessionHostOsDiskType
    tags: union(globalTags, sessionHostTags)
  }
}

@description('Resource group name used for deployment.')
output resourceGroupName string = rg.name

@description('Resource group location used for deployment.')
output resourceGroupLocation string = rg.location

@description('Host Pool resource ID.')
output hostPoolResourceId string = hostPool.outputs.resourceId

@description('Application Group resource ID.')
output applicationGroupResourceId string = applicationGroup.outputs.resourceId

@description('Workspace resource ID.')
output workspaceResourceId string = workspace.outputs.resourceId

@description('Scaling Plan resource ID.')
output scalingPlanResourceId string = scalingPlan.outputs.resourceId

@description('Virtual Network resource ID (when deployed).')
output vnetResourceId string = vnet.?outputs.vnetResourceId ?? ''

@description('AVD session hosts subnet resource ID (when deployVirtualNetwork is true, or from parameter when provided).')
output avdshSubnetResourceId string = vnet.?outputs.avdshSubnetResourceId ?? sessionHostSubnetResourceId

@description('Session host VM resource IDs (when deployed).')
output sessionHostResourceIds array = sessionHosts.?outputs.sessionHostResourceIds ?? []

@description('Session host VM names (when deployed).')
output sessionHostNames array = sessionHosts.?outputs.sessionHostNames ?? []
