targetScope = 'resourceGroup'

// ============================================================================
// AVD Autoscale RBAC - Azure Virtual Desktop
// Assigns the "Desktop Virtualization Power On Off Contributor" built-in role
// to the Windows Virtual Desktop service principal on this resource group.
// This is required for the AVD Scaling Plan to start and deallocate session
// host VMs during autoscale operations.
// Reference: https://learn.microsoft.com/azure/virtual-desktop/autoscale-scaling-plan
// ============================================================================

@sys.description('Required. Object ID of the Windows Virtual Desktop service principal in this tenant.')
param avdServicePrincipalObjectId string

// "Desktop Virtualization Power On Off Contributor" built-in role definition ID.
// This is a well-known, fixed GUID across all Azure tenants.
var desktopVirtualizationPowerOnOffContributorRoleId = '40c5ff49-9181-41f8-ae61-143b0e78555e'

resource avdScalingPlanRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, avdServicePrincipalObjectId, desktopVirtualizationPowerOnOffContributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      desktopVirtualizationPowerOnOffContributorRoleId
    )
    principalId: avdServicePrincipalObjectId
    principalType: 'ServicePrincipal'
  }
}
