// ============================================================================
// Host Pool - Parameter File
// ============================================================================
// Usage: az deployment group create \
//   --resource-group <rg-name> \
//   --template-file main.bicep \
//   --parameters main.bicepparam
// ============================================================================

using 'main.bicep'

// ── Naming ──────────────────────────────────────────────────────────────────
param name = 'vdpool-avd-prod-001'

// ── Region ───────────────────────────────────────────────────────────────────
param location = 'eastus2'

// ── Display metadata ─────────────────────────────────────────────────────────
param friendlyName = 'AVD Production Host Pool'
param description  = 'Pooled host pool for AVD production environment (WAF-aligned).'

// ── Host Pool configuration ───────────────────────────────────────────────────
// Pooled: shared session hosts | Personal: dedicated persistent desktops
param hostPoolType = 'Pooled'

// BreadthFirst spreads users evenly; DepthFirst fills hosts before moving to next
param loadBalancerType = 'BreadthFirst'

// Maximum concurrent sessions per session host VM
param maxSessionLimit = 10

// Desktop: full desktop experience | RailApplications: individual RemoteApp programs
param preferredAppGroupType = 'Desktop'

// Allow users to start a deallocated VM when connecting (requires Power On/Off RBAC role)
param startVMOnConnect = true

// Set to true only for pre-production rings receiving early features
param validationEnvironment = false

// WAF-recommended RDP settings: audio input, clipboard, drive, printer, smart card redirect
param customRdpProperty = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;'

// ── Observability (WAF: Operational Excellence) ───────────────────────────────
// Replace with the resource ID of your Log Analytics Workspace to enable diagnostics.
// Example: /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
param logAnalyticsWorkspaceResourceId = ''

// ── Tags (WAF: Cost Management / Governance) ──────────────────────────────────
param tags = {
  Environment:    'Production'
  Workload:       'AVD'
  Component:      'HostPool'
  CostCenter:     'IT-Infrastructure'
  ManagedBy:      'GitHub-Actions'
}
