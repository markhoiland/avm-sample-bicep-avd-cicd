# Module: application-group

Deploys an **Azure Virtual Desktop Application Group** (`Microsoft.DesktopVirtualization/applicationGroups`) via the [AVM module `avm/res/desktop-virtualization/application-group`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/desktop-virtualization/application-group). Supports both `Desktop` (full desktop) and `RemoteApp` (published individual apps) group types.

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) calls this module at resource-group scope:

```bicep
module applicationGroup './modules/application-group/main.bicep' = {
  name: 'applicationGroup-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    name: applicationGroupName
    location: resourceGroupLocation
    applicationGroupType: applicationGroupType
    hostpoolName: hostPool.outputs.name       // depends on host-pool module
    friendlyName: applicationGroupFriendlyName
    description: applicationGroupDescription
    showInFeed: applicationGroupShowInFeed
    roleAssignments: varApplicationGroupRoleAssignments
    logAnalyticsWorkspaceResourceId: applicationGroupLogAnalyticsWorkspaceResourceId
    tags: union(globalTags, applicationGroupTags)
  }
}
```

> **Dependency note:** `hostpoolName` must reference an already-existing Host Pool. In `main.bicep` this is satisfied by `hostPool.outputs.name`, which creates an implicit `dependsOn`.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | ✅ | — | Name of the Application Group. Min length 3. Recommended: `vdag-<workload>-<env>-<###>`. |
| `location` | `string` | | Resource group location | Azure region for the Application Group. |
| `applicationGroupType` | `string` | ✅ | — | `Desktop` for full desktop or `RemoteApp` for individual published apps. |
| `hostpoolName` | `string` | ✅ | — | Name of the existing Host Pool to associate this group with. |
| `friendlyName` | `string` | | `name` | Display name shown in the AVD client feed. |
| `description` | `string` | | `''` | Free-text description. |
| `showInFeed` | `bool` | | `true` | Whether this Application Group appears in users' AVD feed. |
| `applications` | `array` | | `[]` | RemoteApp application objects to publish. Only relevant when `applicationGroupType` is `RemoteApp`. |
| `diagnosticSettings` | `array` | | `[]` | Full AVM-style diagnosticSettings array. When provided, takes precedence over `logAnalyticsWorkspaceResourceId`. |
| `logAnalyticsWorkspaceResourceId` | `string` | | `''` | Resource ID of a Log Analytics Workspace. Used to auto-build a simple `allLogs` diagnostic setting when `diagnosticSettings` is empty. |
| `lock` | `object` | | `{ kind: 'CanNotDelete' }` | Resource lock. Pass `{}` to disable. |
| `roleAssignments` | `array` | | `[]` | Role assignments to apply to this Application Group (e.g. `Desktop Virtualization User`). |
| `enableTelemetry` | `bool` | | `true` | Enable or disable AVM telemetry. |
| `tags` | `object` | | `{}` | Tags applied to all deployed resources. |

### `roleAssignments` array — element shape

```bicep
{
  roleDefinitionIdOrName: 'Desktop Virtualization User'  // built-in role name, GUID, or full ARM ID
  principalId: '<object-id>'                             // user, group, or service principal object ID
  principalType: 'Group'                                 // User | Group | ServicePrincipal | Device
}
```

In `main.bicep`, the `varApplicationGroupRoleAssignments` variable builds this array from the scalar `applicationGroupPrincipalId` / `applicationGroupPrincipalType` parameters.

### `applications` array — element shape (RemoteApp)

```bicep
{
  name: 'MyApp'
  applicationType: 'InBuilt'         // InBuilt | MsixApplication
  filePath: 'C:\\Windows\\notepad.exe'
  friendlyName: 'Notepad'
  iconIndex: 0
  iconPath: 'C:\\Windows\\notepad.exe'
  showInPortal: true
}
```

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `resourceId` | `string` | Full ARM resource ID of the Application Group. |
| `name` | `string` | Name of the deployed Application Group. |
| `location` | `string` | Azure region of the Application Group. |
| `resourceGroupName` | `string` | Resource group containing the Application Group. |

---

## Governance defaults

| Feature | Default behaviour |
|---------|------------------|
| Resource lock | `CanNotDelete` — prevents accidental deletion |
| Diagnostics | Enabled when `logAnalyticsWorkspaceResourceId` is set (all log categories) |

---

## Example: standalone deployment

```bicep
module applicationGroup './modules/application-group/main.bicep' = {
  name: 'applicationGroup'
  params: {
    name: 'vdag-avd-prod-001'
    location: 'eastus'
    applicationGroupType: 'Desktop'
    hostpoolName: 'vdpool-avd-prod-001'
    friendlyName: 'AVD Production Desktop'
    showInFeed: true
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Desktop Virtualization User'
        principalId: '<avd-users-group-object-id>'
        principalType: 'Group'
      }
    ]
    tags: {
      Environment: 'Production'
      Workload: 'AVD'
    }
  }
}
```
