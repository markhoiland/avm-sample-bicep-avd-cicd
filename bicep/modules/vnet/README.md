# Module: vnet

Deploys an **Azure Virtual Network** with a dedicated AVD session-hosts subnet via the [AVM module `avm/res/network/virtual-network`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/network/virtual-network). Additional subnets (e.g. for private endpoints or management hosts) can be appended through the `additionalSubnets` parameter.

---

## Usage from `main.bicep`

The orchestration file (`bicep/main.bicep`) deploys this module conditionally at resource-group scope:

```bicep
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
```

Set `deployVirtualNetwork = true` in your parameter file to enable this module. The `avdshSubnetResourceId` output is then passed automatically to the session-hosts module via the safe-navigation operator:

```bicep
subnetResourceId: !empty(sessionHostSubnetResourceId)
  ? sessionHostSubnetResourceId
  : (vnet.?outputs.avdshSubnetResourceId ?? '')
```

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | `string` | | Resource group location | Azure region for the VNet. |
| `vnetName` | `string` | ✅ | — | Name of the Virtual Network. Recommended: `vnet-<workload>-<env>-<###>`. |
| `vnetAddressPrefix` | `string` | | `'10.0.0.0/16'` | CIDR address space for the VNet (e.g. `10.29.0.0/16`). |
| `avdshSubnetName` | `string` | | `'snet-avdsh'` | Name for the AVD session-hosts subnet. |
| `avdshSubnetPrefix` | `string` | | `'10.0.1.0/24'` | CIDR address prefix for the AVD session-hosts subnet (must be within `vnetAddressPrefix`). |
| `additionalSubnets` | `array` | | `[]` | Additional subnet objects appended after the AVD session-hosts subnet. See shape below. |
| `logAnalyticsWorkspaceResourceId` | `string` | | `''` | Resource ID of a Log Analytics Workspace for VNet diagnostics. Leave empty to skip. |
| `tags` | `object` | | `{}` | Tags applied to all resources deployed by this module. |

> **Note on Log Analytics cross-subscription:** The deployment principal requires `Microsoft.OperationalInsights/workspaces/sharedkeys/action` on the linked workspace. Cross-subscription references are typically denied. Use a workspace in the same subscription as the AVD resources, or leave the parameter empty.

### `additionalSubnets` array — element shape

```bicep
{
  name: 'snet-pe'                    // subnet name
  addressPrefix: '10.29.2.0/24'     // CIDR, must be within the VNet address space
  // Optional AVM properties:
  networkSecurityGroupResourceId: '/subscriptions/.../nsg-pe'
  routeTableResourceId: '/subscriptions/.../rt-avd'
}
```

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vnetResourceId` | `string` | Full ARM resource ID of the Virtual Network. |
| `vnetName` | `string` | Name of the deployed Virtual Network. |
| `avdshSubnetResourceId` | `string` | Full ARM resource ID of the AVD session-hosts subnet. Passed to the session-hosts module. |
| `subnetResourceIds` | `array` | Array of ARM resource IDs for all subnets in the VNet. |

---

## Example: standalone deployment

```bicep
module vnet './modules/vnet/main.bicep' = {
  name: 'vnet'
  params: {
    vnetName: 'vnet-avd-prod-001'
    location: 'eastus'
    vnetAddressPrefix: '10.29.0.0/16'
    avdshSubnetName: 'snet-avdsh'
    avdshSubnetPrefix: '10.29.1.0/24'
    additionalSubnets: [
      {
        name: 'snet-pe'
        addressPrefix: '10.29.2.0/24'
      }
    ]
    tags: {
      Environment: 'Production'
      Workload: 'AVD'
    }
  }
}
```
