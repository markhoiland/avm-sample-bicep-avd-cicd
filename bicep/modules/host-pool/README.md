# Module: host-pool

Deploys an **Azure Virtual Desktop Host Pool** (`Microsoft.DesktopVirtualization/hostPools`) directly via the ARM API. Supports an optional registration-token parameter so that session hosts can be registered in the same deployment run.

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) calls this module at resource-group scope:

```bicep
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
```

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | ✅ | — | Name of the Host Pool. Recommended format: `vdpool-<workload>-<env>-<###>`. |
| `location` | `string` | | Resource group location | Azure region for the Host Pool. |
| `friendlyName` | `string` | | `name` | Display name shown in the AVD client. |
| `description` | `string` | | `''` | Free-text description of the Host Pool. |
| `hostPoolType` | `string` | | `'Pooled'` | `Pooled` (shared session hosts) or `Personal` (persistent desktops). |
| `loadBalancerType` | `string` | | `'BreadthFirst'` | `BreadthFirst` (spread users across hosts), `DepthFirst` (fill hosts first), or `Persistent` (Personal pools). |
| `maxSessionLimit` | `int` | | `10` | Maximum concurrent sessions per session host. |
| `preferredAppGroupType` | `string` | | `'Desktop'` | `Desktop`, `None`, or `RailApplications`. |
| `startVMOnConnect` | `bool` | | `true` | Power on deallocated session hosts when a user connects. |
| `validationEnvironment` | `bool` | | `false` | Mark the pool as a validation environment (receives AVD updates first). |
| `customRdpProperty` | `string` | | *(full RDP string)* | Custom RDP properties string controlling audio, clipboard, printer redirection, etc. |
| `publicNetworkAccess` | `string` | | `'Enabled'` | `Enabled` or `Disabled`. |
| `personalDesktopAssignmentType` | `string` | | `''` | `Automatic` or `Direct`. Only applies when `hostPoolType` is `Personal`. |
| `vmTemplate` | `object` | | `{}` | VM template used when provisioning session hosts from the AVD portal. |
| `agentUpdate` | `object` | | `{}` | Scheduled maintenance window configuration for session host agents. |
| `logAnalyticsWorkspaceResourceId` | `string` | | `''` | Resource ID of a Log Analytics Workspace for diagnostics. Leave empty to skip. |
| `lock` | `object` | | `{ kind: 'CanNotDelete' }` | Resource lock. Pass `{}` to disable. |
| `tags` | `object` | | `{}` | Tags applied to all resources deployed by this module. |
| `registrationInfo` | `object` | | `{}` | Pass `{ expirationTime: '<ISO8601>', registrationTokenOperation: 'Update' }` to generate a registration token at deploy time. |

### `registrationInfo` object shape

```bicep
{
  expirationTime: dateTimeAdd(deploymentTime, 'PT2H')  // token valid for 2 hours
  registrationTokenOperation: 'Update'                  // always 'Update' for new tokens
}
```

Pass an empty object (`{}`) to skip token generation (e.g. when session hosts are not deployed in the same run).

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `resourceId` | `string` | Full ARM resource ID of the Host Pool. |
| `name` | `string` | Name of the deployed Host Pool. |
| `location` | `string` | Azure region of the Host Pool. |
| `resourceGroupName` | `string` | Resource group containing the Host Pool. |
| `registrationToken` | `string` *(secure)* | Host Pool registration token. Only populated when `registrationInfo` was supplied. Marked `@secure()` so it is redacted from ARM deployment history and GitHub Actions logs. |

---

## Governance defaults

| Feature | Default behaviour |
|---------|------------------|
| Resource lock | `CanNotDelete` — prevents accidental deletion |
| Diagnostics | Enabled when `logAnalyticsWorkspaceResourceId` is set (all log categories) |

---

## Example: standalone deployment

```bicep
module hostPool './modules/host-pool/main.bicep' = {
  name: 'hostPool'
  params: {
    name: 'vdpool-avd-prod-001'
    location: 'eastus'
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    maxSessionLimit: 10
    startVMOnConnect: true
    tags: {
      Environment: 'Production'
      Workload: 'AVD'
    }
  }
}
```
