# Module: workspace

Deploys an **Azure Virtual Desktop Workspace** (`Microsoft.DesktopVirtualization/workspaces`) via the [AVM module `avm/res/desktop-virtualization/workspace`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/desktop-virtualization/workspace). The Workspace aggregates one or more Application Groups and serves as the single endpoint that users subscribe to via the AVD client.

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) calls this module at resource-group scope:

```bicep
module workspace './modules/workspace/main.bicep' = {
  name: 'workspace-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    name: workspaceName
    location: resourceGroupLocation
    friendlyName: workspaceFriendlyName
    description: workspaceDescription
    applicationGroupReferences: concat(
      [applicationGroup.outputs.resourceId],   // depends on application-group module
      workspaceAdditionalApplicationGroupReferences
    )
    publicNetworkAccess: workspacePublicNetworkAccess
    logAnalyticsWorkspaceResourceId: workspaceLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, workspaceTags)
  }
}
```

> **Dependency note:** `applicationGroupReferences` includes `applicationGroup.outputs.resourceId`, creating an implicit `dependsOn` on the application-group module.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | ✅ | — | Name of the Workspace. Recommended: `vdws-<workload>-<env>-<###>`. |
| `location` | `string` | | Resource group location | Azure region for the Workspace. |
| `friendlyName` | `string` | | `name` | Display name shown in the AVD client. |
| `description` | `string` | | `''` | Free-text description. |
| `applicationGroupReferences` | `array` | | `[]` | List of Application Group resource IDs to register with this Workspace. |
| `publicNetworkAccess` | `string` | | `'Enabled'` | `Enabled`, `Disabled`, `EnabledForClientsOnly`, or `EnabledForSessionHostsOnly`. |
| `diagnosticSettings` | `array` | | `[]` | Full AVM-style diagnosticSettings array. When provided, takes precedence over `logAnalyticsWorkspaceResourceId`. |
| `logAnalyticsWorkspaceResourceId` | `string` | | `''` | Resource ID of a Log Analytics Workspace. Used to auto-build a simple `allLogs` diagnostic setting when `diagnosticSettings` is empty. |
| `lock` | `object` | | `{ kind: 'CanNotDelete' }` | Resource lock. Pass `{}` to disable. |
| `roleAssignments` | `array` | | `[]` | Role assignments to apply to this Workspace. |
| `privateEndpoints` | `array` | | `[]` | Private endpoint configurations. Supported services: `feed`, `global`. |
| `enableTelemetry` | `bool` | | `true` | Enable or disable AVM telemetry. |
| `tags` | `object` | | `{}` | Tags applied to all deployed resources. |

### `privateEndpoints` array — element shape

```bicep
{
  subnetResourceId: '/subscriptions/.../subnets/snet-pe'
  service: 'feed'       // feed | global
  privateDnsZoneGroup: {
    privateDnsZoneGroupConfigs: [
      {
        privateDnsZoneResourceId: '/subscriptions/.../privateDnsZones/privatelink.wvd.microsoft.com'
      }
    ]
  }
}
```

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `resourceId` | `string` | Full ARM resource ID of the Workspace. |
| `name` | `string` | Name of the deployed Workspace. |
| `location` | `string` | Azure region of the Workspace. |
| `resourceGroupName` | `string` | Resource group containing the Workspace. |

---

## Governance defaults

| Feature | Default behaviour |
|---------|------------------|
| Resource lock | `CanNotDelete` — prevents accidental deletion |
| Diagnostics | Enabled when `logAnalyticsWorkspaceResourceId` is set (all log categories) |

---

## Example: standalone deployment

```bicep
module workspace './modules/workspace/main.bicep' = {
  name: 'workspace'
  params: {
    name: 'vdws-avd-prod-001'
    location: 'eastus'
    friendlyName: 'AVD Production Workspace'
    applicationGroupReferences: [
      '/subscriptions/<sub>/resourceGroups/rg-avd-prod-001/providers/Microsoft.DesktopVirtualization/applicationGroups/vdag-avd-prod-001'
    ]
    publicNetworkAccess: 'Enabled'
    tags: {
      Environment: 'Production'
      Workload: 'AVD'
    }
  }
}
```
