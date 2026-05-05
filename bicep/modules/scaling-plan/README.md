# Module: scaling-plan

Deploys an **Azure Virtual Desktop Scaling Plan** (`Microsoft.DesktopVirtualization/scalingPlans`) via the [AVM module `avm/res/desktop-virtualization/scaling-plan`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/desktop-virtualization/scaling-plan). The Scaling Plan automates session host power management across ramp-up, peak, ramp-down, and off-peak phases.

> **Prerequisites:** The Windows Virtual Desktop service principal must hold the **Desktop Virtualization Power On Off Contributor** role on the resource group before the Scaling Plan can manage host power state. See the [`avd-autoscale-rbac`](../avd-autoscale-rbac/README.md) module.

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) calls this module at resource-group scope:

```bicep
module scalingPlan './modules/scaling-plan/main.bicep' = {
  name: 'scalingPlan-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  dependsOn: [avdAutoscaleRbac]   // RBAC must propagate before Scaling Plan associates with host pool
  params: {
    name: scalingPlanName
    location: resourceGroupLocation
    friendlyName: scalingPlanFriendlyName
    description: scalingPlanDescription
    timeZone: scalingPlanTimeZone
    hostPoolType: scalingPlanHostPoolType
    hostPoolReferences: !empty(avdServicePrincipalObjectId)
      ? [{ hostPoolResourceId: hostPool.outputs.resourceId, scalingPlanEnabled: true }]
      : []
    schedules: scalingPlanSchedules
    logAnalyticsWorkspaceResourceId: scalingPlanLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, scalingPlanTags)
  }
}
```

> **Dependency note:** `dependsOn: [avdAutoscaleRbac]` ensures the RBAC assignment has propagated before ARM attempts to associate the Scaling Plan with the host pool. The deployment includes a built-in retry with 120 s wait to handle residual propagation delay.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | ✅ | — | Name of the Scaling Plan. Recommended: `vdscaling-<workload>-<env>-<###>`. |
| `location` | `string` | | Resource group location | Azure region for the Scaling Plan. |
| `friendlyName` | `string` | | `name` | Display name for the Scaling Plan. |
| `description` | `string` | | `''` | Free-text description. |
| `timeZone` | `string` | | `'Eastern Standard Time'` | Windows or IANA time zone name for schedule evaluation. |
| `hostPoolType` | `string` | | `'Pooled'` | `Pooled` or `Personal`. Must match the associated Host Pool type. |
| `hostPoolReferences` | `array` | | `[]` | List of Host Pool references. Leave empty to deploy the plan without host pool associations. |
| `schedules` | `array` | | `[]` | Scaling schedule definitions. See the schedule shape below. |
| `diagnosticSettings` | `array` | | `[]` | Full AVM-style diagnosticSettings array. Takes precedence over `logAnalyticsWorkspaceResourceId`. |
| `logAnalyticsWorkspaceResourceId` | `string` | | `''` | Resource ID of a Log Analytics Workspace for diagnostics. |
| `lock` | `object` | | `{ kind: 'CanNotDelete' }` | Resource lock. Pass `{}` to disable. |
| `roleAssignments` | `array` | | `[]` | Role assignments to apply to this Scaling Plan. |
| `enableTelemetry` | `bool` | | `true` | Enable or disable AVM telemetry. |
| `tags` | `object` | | `{}` | Tags applied to all deployed resources. |

### `hostPoolReferences` array — element shape

```bicep
{
  hostPoolResourceId: hostPool.outputs.resourceId  // full ARM resource ID of the target Host Pool
  scalingPlanEnabled: true                          // enable or pause autoscaling for this pool
}
```

### `schedules` array — element shape

```bicep
{
  name: 'Weekday-Schedule'
  daysOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
  rampUpStartTime: { hour: 7, minute: 0 }
  rampUpLoadBalancingAlgorithm: 'BreadthFirst'
  rampUpMinimumHostsPct: 20
  rampUpCapacityThresholdPct: 60
  peakStartTime: { hour: 9, minute: 0 }
  peakLoadBalancingAlgorithm: 'BreadthFirst'
  rampDownStartTime: { hour: 17, minute: 0 }
  rampDownLoadBalancingAlgorithm: 'DepthFirst'
  rampDownMinimumHostsPct: 10
  rampDownCapacityThresholdPct: 90
  rampDownForceLogoffUsers: false
  rampDownWaitTimeMinutes: 30
  rampDownNotificationMessage: 'You will be logged off in 30 minutes. Please save your work.'
  rampDownStopHostsWhen: 'ZeroSessions'
  offPeakStartTime: { hour: 20, minute: 0 }
  offPeakLoadBalancingAlgorithm: 'DepthFirst'
}
```

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `resourceId` | `string` | Full ARM resource ID of the Scaling Plan. |
| `name` | `string` | Name of the deployed Scaling Plan. |
| `location` | `string` | Azure region of the Scaling Plan. |
| `resourceGroupName` | `string` | Resource group containing the Scaling Plan. |

---

## Governance defaults

| Feature | Default behaviour |
|---------|------------------|
| Resource lock | `CanNotDelete` — prevents accidental deletion |
| Diagnostics | Enabled when `logAnalyticsWorkspaceResourceId` is set (all log categories) |

---

## Example: standalone deployment

```bicep
module scalingPlan './modules/scaling-plan/main.bicep' = {
  name: 'scalingPlan'
  params: {
    name: 'vdscaling-avd-prod-001'
    location: 'eastus'
    timeZone: 'Eastern Standard Time'
    hostPoolType: 'Pooled'
    hostPoolReferences: [
      {
        hostPoolResourceId: '/subscriptions/<sub>/resourceGroups/rg-avd-prod-001/providers/Microsoft.DesktopVirtualization/hostPools/vdpool-avd-prod-001'
        scalingPlanEnabled: true
      }
    ]
    schedules: [
      {
        name: 'Weekday-Schedule'
        daysOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
        rampUpStartTime: { hour: 7, minute: 0 }
        rampUpLoadBalancingAlgorithm: 'BreadthFirst'
        rampUpMinimumHostsPct: 20
        rampUpCapacityThresholdPct: 60
        peakStartTime: { hour: 9, minute: 0 }
        peakLoadBalancingAlgorithm: 'BreadthFirst'
        rampDownStartTime: { hour: 17, minute: 0 }
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 10
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: false
        rampDownWaitTimeMinutes: 30
        rampDownNotificationMessage: 'You will be logged off in 30 minutes. Please save your work.'
        rampDownStopHostsWhen: 'ZeroSessions'
        offPeakStartTime: { hour: 20, minute: 0 }
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
      }
    ]
    tags: {
      Environment: 'Production'
      Workload: 'AVD'
    }
  }
}
```
