# AVM Bicep Sample for AVD with GitHub Actions

> **Bootstrap an Azure Virtual Desktop (AVD) environment using Bicep Azure Verified Modules with a secure, OIDC-based GitHub Actions CI/CD pipeline.**

---

## Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [What Gets Deployed](#what-gets-deployed)
   - [Host Pool](#host-pool)
   - [Application Group](#application-group)
   - [Workspace](#workspace)
   - [Scaling Plan](#scaling-plan)
   - [Virtual Network (Optional)](#virtual-network-optional)
   - [Session Hosts](#session-hosts)
4. [Well-Architected Framework (WAF) Alignment](#well-architected-framework-waf-alignment)
5. [Advanced Module Parameters](#advanced-module-parameters)
   - [Role Assignments](#role-assignments)
   - [Private Endpoints](#private-endpoints)
   - [Diagnostic Settings](#diagnostic-settings)
   - [Resource Lock](#resource-lock)
   - [Applications (RemoteApp)](#applications-remoteapp)
   - [Host Pool – Additional Parameters](#host-pool--additional-parameters)
6. [Prerequisites](#prerequisites)
7. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
  - [Step 1 (Optional) – Pre-create an Azure Resource Group](#step-1-optional--pre-create-an-azure-resource-group)
   - [Step 2 – Register an App in Entra ID](#step-2--register-an-app-in-entra-id)
   - [Step 3 – Add a Federated Identity Credential (OIDC)](#step-3--add-a-federated-identity-credential-oidc)
   - [Step 4 – Assign Azure RBAC Roles](#step-4--assign-azure-rbac-roles)
   - [Step 5 – Configure GitHub Secrets](#step-5--configure-github-secrets)
   - [Step 6 – Configure GitHub Environment Protection](#step-6--configure-github-environment-protection)
   - [Step 7 – Customise the Parameter Files](#step-7--customise-the-parameter-files)
   - [Step 8 – Run the Pipeline](#step-8--run-the-pipeline)
8. [CI/CD Workflow Details](#cicd-workflow-details)
9. [Updating Module Versions](#updating-module-versions)
10. [Contributing](#contributing)
11. [License](#license)

---

## Overview

This repository provides a production-ready Infrastructure-as-Code (IaC) foundation for deploying **Azure Virtual Desktop** using:

| Pillar | Technology |
|--------|-----------|
| Infrastructure | [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview) with [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) |
| Authentication | [OpenID Connect (OIDC)](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect) — no stored credentials |
| CI/CD | [GitHub Actions](https://docs.github.com/en/actions) |
| Governance | Microsoft Azure Well-Architected Framework (WAF) alignment |

**Deployment order** (respects resource dependencies):

```
Host Pool  ──►  Application Group  ──►  Workspace
    │
    ├───────────────────────────────►  Scaling Plan
    │
    └─┬─ (Optional) Virtual Network
      │                   │
      └───────────────────┴───────────►  Session Hosts
```

---

## Repository Structure

```
avm-demo-bicep-avd-cicd/
├── .github/
│   └── workflows/
│       └── deploy-avd.yml              # GitHub Actions CI/CD pipeline
│
├── bicep/
│   ├── main.bicep                      # Subscription-scope orchestrator (creates RG + deploys modules)
│   ├── main.bicepparam                 # Production parameter file
│   ├── main.staging.bicepparam         # Staging parameter file
│   └── modules/
│       ├── host-pool/
│       │   └── main.bicep              # AVM host-pool wrapper (simple + large parameter set)
│       ├── application-group/
│       │   └── main.bicep              # AVM application-group wrapper (simple + large parameter set)
│       ├── workspace/
│       │   └── main.bicep              # AVM workspace wrapper (simple + large parameter set)
│       ├── scaling-plan/
│       │   └── main.bicep              # AVM scaling-plan wrapper (simple + large parameter set)
│       ├── avd-autoscale-rbac/
│       │   └── main.bicep              # Assigns Desktop Virtualization Power On Off Contributor to the AVD SP (required for Scaling Plan autoscale)
│       ├── vnet/
│       │   └── main.bicep              # AVM virtual-network wrapper with AVD session hosts subnet
│       └── session-hosts/
│           └── main.bicep              # Session host VMs with Entra ID join (AVM compute)
│
├── bicepconfig.json                    # Bicep config (registry aliases, linting rules)
├── README.md                           # This file
└── LICENSE
```

---

## What Gets Deployed

### Host Pool

| Property | Value |
|----------|-------|
| **AVM Module** | `br/public:avm/res/desktop-virtualization/host-pool:0.8.1` |
| **Resource type** | `Microsoft.DesktopVirtualization/hostPools` |
| **Default name** | `vdpool-avd-prod-001` |
| **Default type** | Pooled (BreadthFirst load balancing) |
| **Max sessions** | 10 per session host |
| **Start VM on Connect** | Enabled |

The Host Pool is the central AVD control-plane object. Session host VMs register into it, and users connect through it. The wrapper module configures:

- Full RDP redirect capabilities (audio, clipboard, drives, printers, smart cards)
- `CanNotDelete` resource lock (configurable or removable)
- Diagnostic logs forwarded to Log Analytics (when `logAnalyticsWorkspaceResourceId` is set)
- Support for advanced scenarios: private endpoints, role assignments, VM templates, agent update schedules, personal desktop assignment, and public network access controls

---

### Application Group

| Property | Value |
|----------|-------|
| **AVM Module** | `br/public:avm/res/desktop-virtualization/application-group:0.4.2` |
| **Resource type** | `Microsoft.DesktopVirtualization/applicationGroups` |
| **Default name** | `vdag-avd-prod-001` |
| **Default type** | Desktop |

The Application Group is associated with the Host Pool and defines what users see in their AVD feed. A **Desktop** type provides a full Windows desktop session. A **RemoteApp** type publishes individual applications. The wrapper module sets:

- `showInFeed: true` so users can discover the desktop/apps
- `CanNotDelete` resource lock (configurable or removable)
- Diagnostic logs forwarded to Log Analytics (when configured)
- Support for advanced scenarios: published RemoteApp application definitions, role assignments

---

### Workspace

| Property | Value |
|----------|-------|
| **AVM Module** | `br/public:avm/res/desktop-virtualization/workspace:0.9.1` |
| **Resource type** | `Microsoft.DesktopVirtualization/workspaces` |
| **Default name** | `vdws-avd-prod-001` |

The Workspace aggregates one or more Application Groups and is the entry point users see in the [AVD web client](https://rdweb.wvd.microsoft.com/arm/webclient), Windows App, or Remote Desktop client. The wrapper module supports:

- `CanNotDelete` resource lock (configurable or removable)
- Diagnostic logs forwarded to Log Analytics (when configured)
- Advanced scenarios: private endpoints (`feed` and `global` services), role assignments, public network access controls

---

### Scaling Plan

| Property | Value |
|----------|-------|
| **AVM Module** | `br/public:avm/res/desktop-virtualization/scaling-plan:0.5.0` |
| **Resource type** | `Microsoft.DesktopVirtualization/scalingPlans` |
| **Default name** | `vdscaling-avd-prod-001` |
| **Default time zone** | Eastern Standard Time |

The Scaling Plan automates session host power management to reduce cost. The included schedule defines four phases for weekdays:

| Phase | Default Time (ET) | Algorithm |
|-------|------------------|-----------|
| Ramp-up | 07:00 | BreadthFirst |
| Peak | 09:00 | BreadthFirst |
| Ramp-down | 17:00 | DepthFirst |
| Off-peak | 20:00 | DepthFirst |

The wrapper module supports advanced scenarios: multiple schedules (weekday + weekend), role assignments, and configurable lock/diagnostics.

> **Autoscale RBAC:** Before a Scaling Plan can manage host pool power state, the **Azure Virtual Desktop** first-party service principal must hold the `Desktop Virtualization Power On Off Contributor` role on the AVD resource group. This is a tenant-specific role assignment because the service principal's object ID differs per tenant even though its application ID (`9cdead84-a844-4324-93f2-b2e6bb768d07`) is fixed across all Azure tenants.
>
> This template handles this automatically via the `avd-autoscale-rbac` module. The workflow uses the deployment service principal to look up the Windows Virtual Desktop SP object ID via `az ad sp show` at runtime — no additional secret is required. If the lookup succeeds the role assignment is created (idempotent); if the deployment SP lacks Graph read permissions, a warning is emitted and the RBAC module is skipped (the role must then already exist from a prior run or manual setup).
>
> See the [Microsoft docs](https://learn.microsoft.com/azure/virtual-desktop/autoscale-scaling-plan#assign-the-desktop-virtualization-power-on-off-contributor-role-with-the-azure-portal) for background.

---

### Virtual Network (Optional)

| Property | Value |
|----------|-------|
| **AVM Module** | `br/public:avm/res/network/virtual-network:0.5.0` |
| **Resource type** | `Microsoft.Network/virtualNetworks` |
| **Default name** | User-provided (e.g., `vnet-avd-prod-001`) |
| **Default address space** | `10.0.0.0/16` |
| **Default AVD session hosts subnet** | `snet-avdsh` (`10.0.1.0/24`) |

The Virtual Network module is **optional** and designed to simplify networking setup for AVD deployments. When enabled, it automatically creates:

- A VNet with configurable address space
- An `avdsh` subnet for session hosts (configurable name and prefix)
- Support for additional custom subnets
- Diagnostic settings integration with Log Analytics

**To enable VNet deployment**, set:
```bicep
param deployVirtualNetwork = true
param vnetName = 'vnet-avd-prod-001'                           # Required when deployVirtualNetwork=true
param vnetAddressPrefix = '10.0.0.0/16'                        # Optional: customize VNet CIDR
param avdshSubnetName = 'snet-avdsh'                            # Optional: customize subnet name
param avdshSubnetPrefix = '10.0.1.0/24'                         # Optional: customize subnet CIDR
param additionalSubnets = []                                    # Optional: add extra subnets
param vnetLogAnalyticsWorkspaceResourceId = ''                 # Optional: enable diagnostics
```

**When VNet is deployed**, the `avdshSubnetResourceId` output automatically populates the session hosts `subnetResourceId` parameter, eliminating manual subnet reference entry. This is ideal for greenfield deployments where networking is co-created with AVD infrastructure.

**Alternative**: If you have an existing VNet and subnets, you can:
- Set `deployVirtualNetwork = false` (default)
- Provide the existing subnet resource ID directly via `sessionHostSubnetResourceId`
- Both approaches are fully supported

---

### Session Hosts

| Property | Value |
|----------|-------|
| **Custom Module** | `bicep/modules/session-hosts/main.bicep` |
| **VM Image** | Windows 11 multi-session (latest) from Azure Marketplace |
| **Default VM Size** | `Standard_D4s_v3` |
| **Identity Join** | Optional Entra ID (Microsoft Entra ID Join) |
| **Host Pool Registration** | AVD DSC extension installs the RD Agent and registers VMs with the host pool |
| **Registration Token** | Generated automatically at deploy time — no manual step required |
| **Default Count** | 2 session hosts (configurable) |
| **Default Naming** | `vm-avd-sh-001`, `vm-avd-sh-002`, etc. |

The Session Hosts module provisions Windows 11 multi-session VMs and registers them with the AVD host pool using the AVD DSC extension. The extension installs the RD Agent on each VM and completes host pool registration using a token generated automatically at deploy time. Key features:

- **Configurable Count:** Deploy 1–100 session hosts via the `sessionHostCount` parameter
- **Auto-generated Token:** When `deploySessionHosts = true`, the host-pool module generates a 2-hour registration token at deploy time and passes it directly to the session-hosts module — no manual token management required
- **Host Pool Registration:** AVD DSC extension (`Microsoft.Powershell/DSC`) installs the RD Agent and registers each VM with the host pool automatically
- **Entra ID Join:** Optionally join VMs to Entra ID by setting `enableSessionHostEntraIdJoin = true`
- **Marketplace Image:** Windows 11 multi-session (win11-22h2-avd) with latest patches
- **Standard Disks:** Premium managed disks (Premium_LRS) for production workloads
- **Serial Naming:** Predictable naming scheme (`vm-avd-sh-001`, `vm-avd-sh-002`, etc.)

**To enable session host deployment**, set `deploySessionHosts = true` in your parameter file, provide:
- `sessionHostSubnetResourceId` – Subnet where VMs are deployed (OR enable `deployVirtualNetwork = true` to auto-create)
- `sessionHostAdminUsername` – Local admin username for VMs
- `SESSION_HOST_ADMIN_PASSWORD` GitHub secret – Local admin password for VMs (required)
- `enableSessionHostEntraIdJoin` (optional, default `false`) – Set to `true` to join VMs to Microsoft Entra ID

> **Note:** The host pool registration token is generated automatically by the Bicep deployment at deploy time and passed directly to the session-hosts module — no manual token or GitHub secret required.

**Example parameter settings** (`.bicepparam` file):
```bicep
param deploySessionHosts = true
param sessionHostCount = 3
param sessionHostNamePrefix = 'vm-avd-sh'
param sessionHostVmSize = 'Standard_D4s_v3'
param sessionHostSubnetResourceId = '/subscriptions/{subscriptionId}/resourceGroups/{rgName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'
param sessionHostAdminUsername = 'azureuser'
param enableSessionHostEntraIdJoin = false  // optional: set true to join to Entra ID
// sessionHostAdminPassword → set GitHub secret SESSION_HOST_ADMIN_PASSWORD
// (host pool registration token is generated automatically — no secret needed)
```

---

## Well-Architected Framework (WAF) Alignment

Every module is deployed with WAF-recommended settings:

| WAF Pillar | Implementation |
|-----------|---------------|
| **Reliability** | `CanNotDelete` resource locks on all components prevent accidental deletion |
| **Security** | OIDC authentication — no long-lived secrets; principle of least privilege RBAC; private endpoints supported |
| **Cost Optimization** | Scaling Plan powers down idle session hosts outside business hours |
| **Operational Excellence** | Diagnostic settings send all logs to Log Analytics; tags on every resource |
| **Performance Efficiency** | BreadthFirst load balancing distributes users evenly during peak; Start VM on Connect avoids idle VMs |

---

## Advanced Module Parameters

All child modules (`bicep/modules/*/main.bicep`) are designed to support the full [AVM large parameter set](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/desktop-virtualization) while remaining backward-compatible with the simple parent orchestrator (`bicep/main.bicep`). Every advanced parameter is **optional** with a sensible default, so the parent bicep requires no modification for basic deployments.

To use advanced features, call the child modules directly or add pass-through parameters to `bicep/main.bicep` as needed.

### Role Assignments

All four modules accept a `roleAssignments` array. Each entry follows the standard AVM role assignment shape:

```bicep
roleAssignments: [
  {
    roleDefinitionIdOrName: 'Desktop Virtualization User'
    principalId: '<entra-group-or-user-object-id>'
    principalType: 'Group'
  }
]
```

### Private Endpoints

**Host Pool** and **Workspace** modules accept a `privateEndpoints` array. The Workspace supports `feed` and `global` service targets:

```bicep
privateEndpoints: [
  {
    service: 'feed'
    subnetResourceId: '/subscriptions/.../subnets/snet-avd'
    privateDnsZoneGroup: {
      privateDnsZoneGroupConfigs: [
        {
          privateDnsZoneResourceId: '/subscriptions/.../privateDnsZones/privatelink.wvd.microsoft.com'
        }
      ]
    }
  }
]
```

### Diagnostic Settings

All modules support two patterns for diagnostics:

**Simple** – pass a Log Analytics Workspace resource ID (existing behaviour):
```bicep
logAnalyticsWorkspaceResourceId: '/subscriptions/.../workspaces/law-avd-prod'
```

**Full** – pass a complete `diagnosticSettings` array (takes precedence when non-empty):
```bicep
diagnosticSettings: [
  {
    name: 'toLogAnalytics'
    workspaceResourceId: '/subscriptions/.../workspaces/law-avd-prod'
    logCategoriesAndGroups: [{ categoryGroup: 'allLogs' }]
  }
  {
    name: 'toEventHub'
    eventHubName: 'evh-avd-diag'
    eventHubAuthorizationRuleResourceId: '/subscriptions/.../authorizationRules/RootManageSharedAccessKey'
    storageAccountResourceId: '/subscriptions/.../storageAccounts/stavddiag'
    logCategoriesAndGroups: [{ categoryGroup: 'allLogs' }]
  }
]
```

### Resource Lock

All modules default to a `CanNotDelete` lock. To customise or disable:

```bicep
// Change kind
lock: { kind: 'ReadOnly' }

// Disable locking entirely
lock: {}
```

### Applications (RemoteApp)

The **Application Group** module accepts an `applications` array to publish individual RemoteApp applications:

```bicep
applicationGroupType: 'RemoteApp'
applications: [
  {
    name: 'notepad'
    friendlyName: 'Notepad'
    filePath: 'C:\\Windows\\System32\\notepad.exe'
    iconPath: 'C:\\Windows\\System32\\notepad.exe'
    iconIndex: 0
    commandLineSetting: 'DoNotAllow'
    showInPortal: true
  }
]
```

### Host Pool – Additional Parameters

The **Host Pool** module exposes several additional parameters for advanced deployments:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `publicNetworkAccess` | Controls public network access | `'Disabled'` |
| `personalDesktopAssignmentType` | Assignment mode for Personal host pools | `'Automatic'` or `'Direct'` |
| `vmTemplate` | VM provisioning template used in the portal | See AVM docs |
| `agentUpdate` | Scheduled agent maintenance window configuration | `{ type: 'Scheduled', maintenanceWindows: [...] }` |

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Azure subscription | Contributor or Owner role required for initial setup |
| Entra ID (Azure AD) | Permission to register applications and create service principals |
| GitHub repository | This repo or a fork |
| Azure CLI ≥ 2.58 | Only needed for local deployments |
| Bicep CLI ≥ 0.28 | Only needed for local builds/linting |

---

## Step-by-Step Setup Guide

### Step 1 (Optional) – Pre-create an Azure Resource Group

This step is optional. The subscription-scope deployment in `bicep/main.bicep` creates the resource group defined in `bicep/main.bicepparam` (or your selected parameter file).

Use this only if you want to create the resource group ahead of time:

```powershell
az group create `
  --name rg-avd-prod-001 `
  --location eastus2
```

---

### Step 2 – Register an App in Entra ID

GitHub Actions authenticates to Azure using an **App Registration** with no secrets — only a federated OIDC credential.

#### Using the Azure Portal

1. Go to **[Azure Portal](https://portal.azure.com)** → **Microsoft Entra ID** → **App registrations**.
2. Click **+ New registration**.
3. Fill in:
   - **Name:** `sp-avd-cicd-github` (or a name of your choice)
   - **Supported account types:** *Accounts in this organizational directory only*
   - **Redirect URI:** Leave blank
4. Click **Register**.
5. On the overview page, copy and save:
   - **Application (client) ID** → will become `AZURE_CLIENT_ID`
   - **Directory (tenant) ID** → will become `AZURE_TENANT_ID`

#### Using the Azure CLI (PowerShell)

```powershell
$APP = az ad app create --display-name "sp-avd-cicd-github" --query "{appId:appId,objectId:id}" -o json | ConvertFrom-Json
$APP_ID = $APP.appId
$APP_OBJ_ID = $APP.objectId

# Create a service principal for the app
$SP_ID = az ad sp create --id $APP_ID --query id -o tsv

Write-Host "AZURE_CLIENT_ID: $APP_ID"
Write-Host "Service Principal Object ID: $SP_ID"
```

---

### Step 3 – Add a Federated Identity Credential (OIDC)

Federated credentials let GitHub Actions obtain a short-lived Azure token without storing a password or certificate.

#### Using the Azure Portal

1. Navigate to your newly created App Registration.
2. Click **Certificates & secrets** → **Federated credentials** tab.
3. Click **+ Add credential**.
4. Select **GitHub Actions deploying Azure resources** from the scenario dropdown.
5. Fill in:
   - **Organization:** `<your-github-org-or-username>`
   - **Repository:** `avm-demo-bicep-avd-cicd`
   - **Entity type:** `Branch`
   - **GitHub branch name:** `main`
   - **Name:** `github-main-branch`
6. Click **Add**.

> **Tip:** Add a second credential with **Entity type: Pull request** if you want the `what-if` job to run on PRs.

#### For Pull Requests (optional)

Repeat the steps above with:
- **Entity type:** `Pull request`
- **Name:** `github-pull-request`

#### Using the Azure CLI

```powershell
# For the main branch
az ad app federated-credential create `
  --id $APP_OBJ_ID `
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:ref:refs/heads/main",
    "description": "GitHub Actions main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For pull requests (optional)
az ad app federated-credential create `
  --id $APP_OBJ_ID `
  --parameters '{
    "name": "github-pull-request",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:pull_request",
    "description": "GitHub Actions pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Replace `<YOUR_GITHUB_ORG>` and `<YOUR_REPO_NAME>` with your values.

---

### Step 4 – Assign Azure RBAC Roles

The service principal needs permissions to deploy AVD resources.

#### Minimum required role

```powershell
$SUBSCRIPTION_ID = (az account show --query id -o tsv)

az role assignment create `
  --role "Contributor" `
  --assignee-object-id $SP_ID `
  --assignee-principal-type ServicePrincipal `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-avd-prod-001"
```

> **Production recommendation:** Replace `Contributor` with a custom role scoped to only `Microsoft.DesktopVirtualization/*`, `Microsoft.Authorization/locks/*`, and `Microsoft.Insights/diagnosticSettings/*` to follow least-privilege principles.

#### Additional role for Scaling Plan (Start VM on Connect)

If session host VMs are in the same resource group:

```powershell
az role assignment create `
  --role "Desktop Virtualization Power On Off Contributor" `
  --assignee-object-id $SP_ID `
  --assignee-principal-type ServicePrincipal `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-avd-prod-001"
```

---

### Step 5 – Configure GitHub Secrets

In your GitHub repository, navigate to **Settings → Secrets and variables → Actions**.

#### Secrets (encrypted, not visible in logs)

**Required (authentication):**

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | Application (client) ID from Step 2 |
| `AZURE_TENANT_ID` | Directory (tenant) ID from Step 2 |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

**Optional (required when `deploySessionHosts = true`):**

| Secret Name | Value |
|-------------|-------|
| `SESSION_HOST_ADMIN_PASSWORD` | Local administrator password for session host VMs. Required for both Entra ID join and Active Directory join scenarios. |

**Optional (recommended for autoscale RBAC):**

| Secret Name | Value |
|-------------|-------|
| `AVD_SP_OBJECT_ID` | Object ID of the **Windows Virtual Desktop** service principal in your tenant. Retrieve with: `az ad sp show --id 9cdead84-a844-4324-93f2-b2e6bb768d07 --query id -o tsv` |

> **Why is `AVD_SP_OBJECT_ID` recommended?** The Scaling Plan needs `Desktop Virtualization Power On Off Contributor` assigned to the Windows Virtual Desktop service principal on the AVD resource group. The workflow looks up the object ID from this secret first — guaranteeing the correct SP object ID without requiring Microsoft Graph permissions on the workload identity. If the secret is not configured, the pipeline falls back to `az ad sp show` at runtime; if that lookup does not resolve to a non-empty object ID value, the RBAC module is skipped and a warning is emitted (the role assignment must then already exist from a prior run or manual setup).

To add a secret:
1. Click **New repository secret**.
2. Enter the **Name** and **Value**.
3. Click **Add secret**.

No repository variables are required for resource group name or location. Those values are managed in `bicep/main.bicepparam`.

---

### Step 6 – Configure GitHub Environment Protection

The workflow uses a **`production`** environment for all deployment jobs. Environment protection rules add an approval gate before changes go live.

1. Go to **Settings → Environments**.
2. Click **New environment**, name it `production`, click **Configure environment**.
3. Under **Deployment protection rules**, check **Required reviewers**.
4. Add the GitHub user(s) who must approve deployments.
5. Click **Save protection rules**.

---

### Step 7 – Customise the Parameter Files

Review and update `bicep/main.bicepparam` before your first deployment. This is the single source of truth for:

- Resource group name/location
- Shared tags
- Host Pool, Application Group, Workspace, and Scaling Plan settings
- Session Hosts configuration (optional)

For a separate staging configuration, use `bicep/main.staging.bicepparam` as the baseline.

#### `bicep/main.bicepparam`

| Parameter | Default | Action |
|-----------|---------|--------|
| `resourceGroupName` | `rg-avd-prod-001` | Set your target resource group name |
| `resourceGroupLocation` | `eastus2` | Set your Azure region |
| `globalTags` | See file | Update common governance/cost tags |
| `hostPoolName` | `vdpool-avd-prod-001` | Rename to match your convention |
| `applicationGroupName` | `vdag-avd-prod-001` | Rename as needed |
| `workspaceName` | `vdws-avd-prod-001` | Rename as needed |
| `scalingPlanName` | `vdscaling-avd-prod-001` | Rename as needed |
| `scalingPlanTimeZone` | `Eastern Standard Time` | Set to your business time zone |
| `deployVirtualNetwork` | `false` | Set to `true` to auto-create a VNet for session hosts |
| `vnetName` | `''` | **Required if deployVirtualNetwork=true**: Name for new VNet |
| `vnetAddressPrefix` | `10.0.0.0/16` | Address space for the VNet |
| `avdshSubnetName` | `snet-avdsh` | Subnet name for session hosts |
| `avdshSubnetPrefix` | `10.0.1.0/24` | Subnet CIDR for session hosts |
| `deploySessionHosts` | `false` | Set to `true` to deploy session host VMs |
| `sessionHostCount` | `2` | Number of session host VMs to deploy |
| `sessionHostSubnetResourceId` | `''` | **Required if deploySessionHosts=true and deployVirtualNetwork=false**: Subnet resource ID for VMs |
| `sessionHostAdminUsername` | `azureuser` | Local admin username for session hosts |
| `enableSessionHostEntraIdJoin` | `false` | Set to `true` to Entra ID join session hosts |
| `avdServicePrincipalObjectId` | `''` | Optional: Object ID of the Windows Virtual Desktop SP. Resolved automatically at runtime by the pipeline via `az ad sp show` — leave as `''` in `.bicepparam` files |

#### Virtual Network Configuration

To enable automatic VNet provisioning for session hosts, set the following in your parameter file:

```bicep
param deployVirtualNetwork = true                           // Auto-create VNet
param vnetName = 'vnet-avd-prod-001'                        // Name for new VNet
param vnetAddressPrefix = '10.0.0.0/16'                     // VNet address space
param avdshSubnetName = 'snet-avdsh'                         // Session hosts subnet name
param avdshSubnetPrefix = '10.0.1.0/24'                     // Session hosts subnet CIDR
param additionalSubnets = []                                // Optional: add more subnets
```

When `deployVirtualNetwork = true`, the orchestrator automatically:
- Creates the VNet with the specified address space
- Creates the `avdsh` subnet for session hosts
- Outputs the subnet resource ID
- Populates `sessionHostSubnetResourceId` automatically (no manual reference needed)

**Alternative (existing VNet):** Leave `deployVirtualNetwork = false` and provide your existing subnet resource ID:

```bicep
param deployVirtualNetwork = false
param sessionHostSubnetResourceId = '/subscriptions/{subscriptionId}/resourceGroups/{rgName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'
```

---

#### Session Hosts Configuration

To enable session host deployment, set the following in your parameter file and add the `SESSION_HOST_ADMIN_PASSWORD` GitHub secret:

```bicep
param deploySessionHosts = true                             // Enable session host deployment
param sessionHostCount = 3                                  // Number of VMs to deploy
param sessionHostNamePrefix = 'vm-avd-sh'                  // VM name prefix
param sessionHostVmSize = 'Standard_D4s_v3'                // VM SKU
param sessionHostSubnetResourceId = ''                      // Auto-populated from VNet if deployVirtualNetwork=true; otherwise required
param sessionHostAdminUsername = 'azureuser'               // Local admin username
param enableSessionHostEntraIdJoin = false                 // Optional: set true for Entra ID join
// sessionHostAdminPassword – provided via GitHub secret SESSION_HOST_ADMIN_PASSWORD
// (host pool registration token is generated automatically at deploy time — no secret needed)
```

> **Security Note:** `sessionHostAdminPassword` must **not** be stored in `.bicepparam` files. The pipeline reads it from the `SESSION_HOST_ADMIN_PASSWORD` GitHub secret and passes it as a secure CLI parameter override at deploy time. The host pool registration token is generated inside the Bicep deployment itself and never stored externally.

---

### Step 8 – Run the Pipeline

#### Automatic trigger (push to `main`)

Any push to `main` that modifies files under `bicep/main.bicep`, `bicep/main.bicepparam`, `bicep/main.staging.bicepparam`, `bicep/modules/`, or the workflow file itself will automatically trigger the pipeline.

#### Manual trigger

1. Go to **Actions** → **Deploy AVD Infrastructure**.
2. Click **Run workflow**.
3. Select the **environment** (`production` or `staging`).
4. The workflow automatically selects the parameter file:
   - `production` → `bicep/main.bicepparam`
   - `staging` → `bicep/main.staging.bicepparam`
5. Optionally set **parameterFileOverride** to an explicit `.bicepparam` path.
6. Parameter precedence is:
   - `parameterFileOverride` (when provided)
   - environment-based default (`production` or `staging`)
7. Optionally set **deploymentLocation** for subscription deployment metadata (defaults to `eastus`).
8. Click **Run workflow**.

#### Pipeline stages

```
validate ──► (PR only) what-if
         └──► (push/dispatch) deploy-platform
                               └──► summary
```

| Job | Trigger | Description |
|-----|---------|-------------|
| `validate` | All events | Builds/lints all Bicep templates: host-pool, application-group, workspace, scaling-plan, session-hosts, and the platform orchestrator |
| `what-if` | Pull requests | Runs `az deployment sub what-if` using `bicep/main.bicepparam` to preview planned changes |
| `deploy-platform` | Push to main / workflow_dispatch | Runs one subscription-scope orchestration deployment with automatic prod/staging parameter-file selection and optional explicit override. Outputs resource IDs and names for all deployed components (including session hosts if enabled) |
| `summary` | After deploy | Writes a markdown summary to the Actions run showing deployment environment, parameter file, resource group, and session host VM names (when deployed) |

#### Deployment Outputs

The `deploy-platform` job captures outputs from the Bicep deployment and makes them available to downstream jobs:

| Output | When Available | Value |
|--------|-----------------|-------|
| `targetEnvironment` | Always | Either `production` or `staging` |
| `parameterFile` | Always | Path to the parameter file used (e.g., `bicep/main.bicepparam`) |
| `resourceGroupName` | Always | Name of the created/targeted resource group |
| `hostPoolResourceId` | Always | Full resource ID of the Host Pool |
| `applicationGroupResourceId` | Always | Full resource ID of the Application Group |
| `workspaceResourceId` | Always | Full resource ID of the Workspace |
| `scalingPlanResourceId` | Always | Full resource ID of the Scaling Plan |
| `vnetResourceId` | When `deployVirtualNetwork=true` | Full resource ID of the Virtual Network (empty string if not deployed) |
| `avdshSubnetResourceId` | When `deployVirtualNetwork=true` | Full resource ID of the AVD session hosts subnet (falls back to `sessionHostSubnetResourceId` parameter if VNet not deployed) |
| `sessionHostResourceIds` | When `deploySessionHosts=true` | Array of session host VM resource IDs |
| `sessionHostNames` | When `deploySessionHosts=true` | Array of session host VM names (e.g., `["vm-avd-sh-001", "vm-avd-sh-002"]`) |

---

## CI/CD Workflow Details

### OIDC Authentication Flow

```
GitHub Actions Runner
       │
       │  1. Request OIDC JWT from GitHub
       ▼
GitHub OIDC Provider (token.actions.githubusercontent.com)
       │
       │  2. Issue JWT signed by GitHub
       ▼
Azure Entra ID (Federated Credential)
       │
       │  3. Exchange JWT for short-lived Azure access token
       ▼
Azure Resource Manager (deployment)
```

No passwords, certificates, or client secrets are stored anywhere. Tokens are valid only for the duration of the pipeline run.

### Security hardening

- `permissions: id-token: write` is declared at the workflow level and scoped to only what's needed.
- Each job re-authenticates independently (no token sharing across jobs).
- The `production` environment gate requires human approval before any deployment.
- `az deployment sub what-if` on PRs lets reviewers inspect planned changes before approving the merge.

---

## Updating Module Versions

AVM modules are published to the Microsoft Container Registry (MCR). To update to a newer version:

1. Check the latest version in the [AVM Bicep modules index](https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-resource-modules/) or the respective `CHANGELOG.md` in [bicep-registry-modules](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/desktop-virtualization).
2. Update the version string in the relevant `bicep/modules/<module>/main.bicep` file:
   ```bicep
   // Example: bump host-pool from 0.8.1 → 0.9.0
   module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.9.0' = {
   ```
3. Review the module's CHANGELOG for any breaking changes and update parameters accordingly.
4. Open a PR — the `validate` and `what-if` jobs will automatically run to confirm there are no issues.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

[MIT](./LICENSE) — Copyright © 2026 Mark Hoiland
