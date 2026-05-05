// ============================================================================
// Scaling Plan - Parameter File
// ============================================================================
// Usage: az deployment group create \
//   --resource-group <rg-name> \
//   --template-file main.bicep \
//   --parameters main.bicepparam
//
// IMPORTANT: Deploy the Host Pool BEFORE the Scaling Plan.
//            Update hostPoolReferences with the actual Host Pool resource ID.
// ============================================================================

using 'main.bicep'

// ── Naming ──────────────────────────────────────────────────────────────────
param name = 'vdscaling-avd-prod-001'

// ── Region ───────────────────────────────────────────────────────────────────
param location = 'eastus2'

// ── Display metadata ─────────────────────────────────────────────────────────
param friendlyName = 'AVD Production Scaling Plan'
param description  = 'Scaling Plan for AVD production host pool (WAF-aligned).'

// ── Time zone ────────────────────────────────────────────────────────────────
// Windows time zone name - used for schedule evaluation
// Common values: 'Eastern Standard Time', 'Central Standard Time',
//                'Mountain Standard Time', 'Pacific Standard Time', 'UTC'
param timeZone = 'Eastern Standard Time'

// ── Host Pool type ───────────────────────────────────────────────────────────
param hostPoolType = 'Pooled'

// ── Host Pool references ─────────────────────────────────────────────────────
// Associate the Scaling Plan with one or more Host Pools.
// Replace the placeholder with the actual Host Pool resource ID.
// Format: /subscriptions/<subId>/resourceGroups/<rg>/providers/
//         Microsoft.DesktopVirtualization/hostPools/<name>
param hostPoolReferences = [
  // {
  //   hostPoolResourceId: '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.DesktopVirtualization/hostPools/vdpool-avd-prod-001'
  //   scalingPlanEnabled: true
  // }
]

// ── Scaling Schedules ─────────────────────────────────────────────────────────
// Defines ramp-up, peak, ramp-down, and off-peak phases for weekdays.
// Times are in 24h HH:MM format, evaluated in the timeZone above.
param schedules = [
  {
    name: 'Weekday-Schedule'
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    // ── Ramp-up ──────────────────────────────────────────────────────────────
    // Start spinning up hosts before users arrive
    rampUpStartTime: {
      hour: 7
      minute: 0
    }
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60

    // ── Peak ─────────────────────────────────────────────────────────────────
    // Core business hours - keep hosts available
    peakStartTime: {
      hour: 9
      minute: 0
    }
    peakLoadBalancingAlgorithm: 'BreadthFirst'

    // ── Ramp-down ─────────────────────────────────────────────────────────────
    // Drain and deallocate hosts as users leave
    rampDownStartTime: {
      hour: 17
      minute: 0
    }
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 10
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: false
    rampDownWaitTimeMinutes: 30
    rampDownNotificationMessage: 'You will be logged off in 30 minutes. Please save your work.'
    rampDownStopHostsWhen: 'ZeroSessions'

    // ── Off-peak ──────────────────────────────────────────────────────────────
    // Outside business hours - minimal hosts running
    offPeakStartTime: {
      hour: 20
      minute: 0
    }
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
  }
]

// ── Observability (WAF: Operational Excellence) ───────────────────────────────
// Replace with the resource ID of your Log Analytics Workspace to enable diagnostics.
// Example: /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
param logAnalyticsWorkspaceResourceId = ''

// ── Tags (WAF: Cost Management / Governance) ──────────────────────────────────
param tags = {
  Environment:    'Production'
  Workload:       'AVD'
  Component:      'ScalingPlan'
  CostCenter:     'IT-Infrastructure'
  ManagedBy:      'GitHub-Actions'
}
