using 'main.bicep'

// ============================================================================
// Platform Orchestration - Parameter File
// Single source of truth for deployment scope and core module settings.
// ============================================================================

// Deployment scope
param resourceGroupName = 'rg-avd-prod-001'
param resourceGroupLocation = 'centralus'

// Shared tags
param globalTags = {
  Environment: 'Production'
  Workload: 'AVD'
  CostCenter: 'IT-Infrastructure'
  ManagedBy: 'Bicep-GitHub-Actions'
}

// Host Pool
param hostPoolName = 'vdpool-avd-prod-001'
param hostPoolFriendlyName = 'AVD Production Host Pool'
param hostPoolDescription = 'Pooled host pool for AVD production environment (WAF-aligned).'
param hostPoolType = 'Pooled'
param hostPoolLoadBalancerType = 'BreadthFirst'
param hostPoolMaxSessionLimit = 10
param hostPoolPreferredAppGroupType = 'Desktop'
param hostPoolStartVMOnConnect = true
param hostPoolValidationEnvironment = false
param hostPoolCustomRdpProperty = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;'
param hostPoolLogAnalyticsWorkspaceResourceId = ''
param hostPoolTags = {
  Component: 'HostPool'
}

// Application Group
param applicationGroupName = 'vdag-avd-prod-001'
param applicationGroupType = 'Desktop'
param applicationGroupFriendlyName = 'AVD Production Desktop'
param applicationGroupDescription = 'Desktop Application Group for AVD production environment (WAF-aligned).'
param applicationGroupShowInFeed = true
param applicationGroupLogAnalyticsWorkspaceResourceId = ''
// Grant 'Desktop Virtualization User' to the AVD users group so they can see and connect to the desktop in their feed.
param applicationGroupPrincipalId = ''
param applicationGroupPrincipalType = 'Group'
param applicationGroupTags = {
  Component: 'ApplicationGroup'
}

// Workspace
param workspaceName = 'vdws-avd-prod-001'
param workspaceFriendlyName = 'AVD Production Workspace'
param workspaceDescription = 'AVD Workspace for production environment (WAF-aligned).'
param workspacePublicNetworkAccess = 'Enabled'
param workspaceAdditionalApplicationGroupReferences = []
param workspaceLogAnalyticsWorkspaceResourceId = ''
param workspaceTags = {
  Component: 'Workspace'
}

// AVD Auto-scaling
// The workflow attempts to resolve the Windows Virtual Desktop service principal object ID
// at runtime via az ad sp show (app ID 9cdead84-a844-4324-93f2-b2e6bb768d07) using the
// deployment SP. If the lookup succeeds the value is passed at deploy time; if not, a
// warning is emitted and the RBAC module is skipped (role must already exist from a prior run).
param avdServicePrincipalObjectId = ''

// Scaling Plan
param scalingPlanName = 'vdscaling-avd-prod-001'
param scalingPlanFriendlyName = 'AVD Production Scaling Plan'
param scalingPlanDescription = 'Scaling Plan for AVD production host pool (WAF-aligned).'
param scalingPlanTimeZone = 'Eastern Standard Time'
param scalingPlanHostPoolType = 'Pooled'
param scalingPlanSchedules = [
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
param scalingPlanLogAnalyticsWorkspaceResourceId = ''
param scalingPlanTags = {
  Component: 'ScalingPlan'
}

// Virtual Network
param deployVirtualNetwork = true
param vnetName = 'vnet-avd-prod-001'
param vnetAddressPrefix = '10.29.0.0/16'
param avdshSubnetName = 'snet-avdsh'
param avdshSubnetPrefix = '10.29.1.0/24'
param additionalSubnets = []
// Cross-subscription Log Analytics workspace references are not supported here: the deployment
// principal requires Microsoft.OperationalInsights/workspaces/sharedKeys/action on the linked
// workspace scope, which is denied across subscription boundaries. Leave empty or use a workspace
// in the same subscription as the AVD resources.
param vnetLogAnalyticsWorkspaceResourceId = ''
param vnetTags = {
  Component: 'VirtualNetwork'
}

// Session Hosts
param deploySessionHosts = true
param sessionHostCount = 2
param sessionHostNamePrefix = 'vm-avd-sh'
param sessionHostVmSize = 'Standard_D4s_v3'
param sessionHostSubnetResourceId = ''
param sessionHostAdminUsername = 'avdadmin'
// sessionHostAdminPassword – set via GitHub secret SESSION_HOST_ADMIN_PASSWORD (never commit passwords)
// The host pool registration token is generated automatically at deploy time — no pipeline secret needed.
param enableSessionHostEntraIdJoin = true
param sessionHostAvailabilityZone = 0
param sessionHostImageSku = 'win11-22h2-avd'
param sessionHostOsDiskType = 'Premium_LRS'
param sessionHostTags = {
  Component: 'SessionHost'
}
