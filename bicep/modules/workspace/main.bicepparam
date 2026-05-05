// ============================================================================
// Workspace - Parameter File
// ============================================================================
// Usage: az deployment group create \
//   --resource-group <rg-name> \
//   --template-file main.bicep \
//   --parameters main.bicepparam
//
// IMPORTANT: Deploy Application Group BEFORE the Workspace.
//            The applicationGroupReferences array must contain the full
//            resource ID(s) of deployed Application Group(s).
// ============================================================================

using 'main.bicep'

// ── Naming ──────────────────────────────────────────────────────────────────
param name = 'vdws-avd-prod-001'

// ── Region ───────────────────────────────────────────────────────────────────
param location = 'eastus2'

// ── Display metadata ─────────────────────────────────────────────────────────
param friendlyName = 'AVD Production Workspace'
param description  = 'AVD Workspace for production environment (WAF-aligned).'

// ── Application Group references ─────────────────────────────────────────────
// Replace the placeholder with the actual Application Group resource ID(s).
// Format: /subscriptions/<subId>/resourceGroups/<rg>/providers/
//         Microsoft.DesktopVirtualization/applicationGroups/<name>
param applicationGroupReferences = [
  // '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.DesktopVirtualization/applicationGroups/vdag-avd-prod-001'
]

// ── Network access (WAF: Security) ───────────────────────────────────────────
// Use 'Disabled' and private endpoints for fully private deployments.
// Use 'Enabled' for standard public connectivity.
param publicNetworkAccess = 'Enabled'

// ── Observability (WAF: Operational Excellence) ───────────────────────────────
// Replace with the resource ID of your Log Analytics Workspace to enable diagnostics.
// Example: /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
param logAnalyticsWorkspaceResourceId = ''

// ── Tags (WAF: Cost Management / Governance) ──────────────────────────────────
param tags = {
  Environment:    'Production'
  Workload:       'AVD'
  Component:      'Workspace'
  CostCenter:     'IT-Infrastructure'
  ManagedBy:      'GitHub-Actions'
}
