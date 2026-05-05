# Module: avd-autoscale-rbac

Assigns the **Desktop Virtualization Power On Off Contributor** built-in role to the **Windows Virtual Desktop** service principal on the target resource group. This RBAC assignment is required for the AVD Scaling Plan to start and deallocate session host VMs during autoscale operations.

Reference: [Configure autoscaling for pooled host pools](https://learn.microsoft.com/azure/virtual-desktop/autoscale-scaling-plan)

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) deploys this module conditionally at resource-group scope:

```bicep
module avdAutoscaleRbac './modules/avd-autoscale-rbac/main.bicep' = if (!empty(avdServicePrincipalObjectId)) {
  name: 'avdAutoscaleRbac-${uniqueString(deployment().name)}'
  scope: resourceGroup(rg.name)
  params: {
    avdServicePrincipalObjectId: avdServicePrincipalObjectId
  }
}
```

The module is skipped when `avdServicePrincipalObjectId` is empty. In that case the Scaling Plan is still deployed but without host-pool associations (autoscaling will not function until the role exists and the parameter is populated on a subsequent run).

### How the pipeline resolves the service principal object ID

The GitHub Actions workflow attempts to resolve the object ID automatically:

1. **Preferred:** Read the `AVD_SP_OBJECT_ID` repository secret (no Microsoft Graph permission required).
2. **Fallback:** Run `az ad sp show --id 9cdead84-a844-4324-93f2-b2e6bb768d07 --query id -o tsv` at deploy time (requires `Application.Read.All` on the workload identity).
3. **Skip:** If neither source yields a value, a warning is emitted and the module is omitted.

To retrieve the value manually:

```bash
az ad sp show --id 9cdead84-a844-4324-93f2-b2e6bb768d07 --query id -o tsv
```

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `avdServicePrincipalObjectId` | `string` | ✅ | — | Object ID of the **Windows Virtual Desktop** first-party service principal in this Entra ID tenant. App ID `9cdead84-a844-4324-93f2-b2e6bb768d07` is the same across all Azure tenants; the object ID is tenant-specific. |

---

## What gets deployed

| Resource | Type | Description |
|----------|------|-------------|
| `avdScalingPlanRoleAssignment` | `Microsoft.Authorization/roleAssignments` | Assigns role `40c5ff49-9181-41f8-ae61-143b0e78555e` (*Desktop Virtualization Power On Off Contributor*) to the AVD service principal at resource-group scope. The assignment name is a stable GUID derived from `(resourceGroupId, principalId, roleDefinitionId)`, making the deployment idempotent. |

---

## Outputs

This module has no outputs. The role assignment is a side-effect that enables the Scaling Plan to manage session host power state.

---

## Deployment order

The `scaling-plan` module in `main.bicep` declares `dependsOn: [avdAutoscaleRbac]` to ensure the role assignment has been created (and has begun propagating through Azure's authorization service) before the Scaling Plan tries to associate with the host pool. The deployment retry logic (120 s wait, up to 2 attempts) handles any residual propagation delay.

---

## Example: standalone deployment

```bicep
module avdAutoscaleRbac './modules/avd-autoscale-rbac/main.bicep' = {
  name: 'avdAutoscaleRbac'
  scope: resourceGroup('rg-avd-prod-001')
  params: {
    avdServicePrincipalObjectId: '<object-id-from-az-ad-sp-show>'
  }
}
```
