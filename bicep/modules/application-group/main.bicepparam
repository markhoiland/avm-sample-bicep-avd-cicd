// ============================================================================
// Application Group - Parameter File
// ============================================================================
// Usage: az deployment group create \
//   --resource-group <rg-name> \
//   --template-file main.bicep \
//   --parameters main.bicepparam
//
// IMPORTANT: Deploy the Host Pool BEFORE the Application Group.
//            The hostpoolName must reference an existing Host Pool in the
//            same resource group.
// ============================================================================

using 'main.bicep'

// ── Naming ──────────────────────────────────────────────────────────────────
param name = 'vdag-avd-prod-001'

// ── Region ───────────────────────────────────────────────────────────────────
param location = 'eastus2'

// ── Application Group type ────────────────────────────────────────────────────
// Desktop: provides a full Windows desktop session
// RemoteApp: provides individual published applications
param applicationGroupType = 'Desktop'

// ── Host Pool reference ───────────────────────────────────────────────────────
// Must match the 'name' parameter used when deploying the Host Pool
param hostpoolName = 'vdpool-avd-prod-001'

// ── Display metadata ─────────────────────────────────────────────────────────
param friendlyName = 'AVD Production Desktop'
param description  = 'Desktop Application Group for AVD production environment (WAF-aligned).'

// ── Feed visibility ───────────────────────────────────────────────────────────
// Set to false if this group should not appear in users' AVD feed
param showInFeed = true

// ── Observability (WAF: Operational Excellence) ───────────────────────────────
// Replace with the resource ID of your Log Analytics Workspace to enable diagnostics.
// Example: /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
param logAnalyticsWorkspaceResourceId = ''

// ── Tags (WAF: Cost Management / Governance) ──────────────────────────────────
param tags = {
  Environment:    'Production'
  Workload:       'AVD'
  Component:      'ApplicationGroup'
  CostCenter:     'IT-Infrastructure'
  ManagedBy:      'GitHub-Actions'
}
