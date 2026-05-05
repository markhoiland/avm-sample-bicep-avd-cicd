targetScope = 'resourceGroup'

// ============================================================================
// Session Hosts - Azure Virtual Desktop
// Deploys session host VMs and registers them with an AVD host pool via the
// AVD DSC extension. Optionally joins VMs to Entra ID.
// Uses Windows 11 multi-session latest marketplace image.
// ============================================================================

@sys.description('Required. Location for session host VMs. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Required. Name of the existing Host Pool to register session hosts with.')
param hostPoolName string

@sys.description('Required. Host Pool registration token used to register session hosts. Generate a token from the Host Pool before deploying.')
@secure()
param hostPoolRegistrationToken string

@sys.description('Required. Subnet resource ID where session hosts will be deployed.')
param subnetResourceId string

@sys.description('Required. Number of session hosts to deploy.')
@minValue(1)
@maxValue(100)
param sessionHostCount int = 2

@sys.description('Optional. Naming prefix for session host VMs (e.g., "vm-avd-sh"). VMs will be named: {prefix}-001, {prefix}-002, etc.')
param sessionHostNamePrefix string = 'vm-avd-sh'

@sys.description('Optional. VM size for session hosts (e.g., "Standard_D4s_v3").')
param vmSize string = 'Standard_D4s_v3'

@sys.description('Required. Admin username for session host VMs.')
param adminUsername string

@sys.description('Required. Admin password for session host VMs.')
@secure()
param adminPassword string

@sys.description('Optional. Set to true to join VMs to Entra ID (Microsoft Entra ID Join).')
param enableEntraIdJoin bool = false

@sys.description('Optional. Role assignments to apply at resource group scope so Entra ID users/groups can log into session host VMs (e.g. Virtual Machine User Login or Virtual Machine Administrator Login). Only relevant when enableEntraIdJoin is true. Each object requires principalId and roleDefinitionIdOrName. principalType (User/Group/ServicePrincipal/Device) is optional but strongly recommended to avoid Azure graph lookup failures for guest or cross-tenant principals.')
param entraIdLoginRoleAssignments array = []

@sys.description('Optional. Availability zone for session host VMs (0 = no zone pinning, 1-3 = specific zone). Defaults to 0 (regional deployment).')
@minValue(0)
@maxValue(3)
param availabilityZone int = 0

@sys.description('Optional. Windows marketplace image SKU for session host VMs. Defaults to win11-22h2-avd (Windows 11 multi-session 22H2). See: az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --all.')
param imageSku string = 'win11-22h2-avd'

@sys.description('Optional. Managed disk storage account type for the OS disk. Defaults to Premium_LRS.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param osDiskType string = 'Premium_LRS'

@sys.description('Optional. Tags applied to all session host VMs.')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

// Pre-mapped GUIDs for well-known VM login role names used with Entra ID Join.
// Any value already containing '/' is treated as a full ARM resource ID and
// passed through unchanged. Any other value is treated as a raw GUID.
var knownRoleDefinitionIds = {
  'Virtual Machine User Login': 'fb879df8-f326-4884-b1cf-06f3ad86be52'
  'Virtual Machine Administrator Login': '1c0163c0-47e6-4577-8991-ea5c82e286e4'
}

var imageReference = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-11'
  sku: imageSku
  version: 'latest'
}

var vmSettingsList = [
  for i in range(0, sessionHostCount): {
    index: i
    vmName: '${sessionHostNamePrefix}-${padLeft(i + 1, 3, '0')}'
  }
]

// AVD DSC extension: installs the RD Agent and registers the VM with the host pool.
// The registration token is passed as a protected setting so it is never exposed in logs.
// Version 1.0.02714.342 is a stable release of the AVD Configuration DSC module.
// To update to a newer version, replace the version number in the URL below. Consult
// https://learn.microsoft.com/azure/virtual-desktop/create-host-pools-azure-marketplace
// for the latest recommended DSC module URL.
// The storage account hostname is an AVD platform endpoint that cannot be expressed via environment().
#disable-next-line no-hardcoded-env-urls
var avdDscModulesUrl = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip'

// ============================================================================
// Session Host Deployment
// ============================================================================

module sessionHostVMs 'br/public:avm/res/compute/virtual-machine:0.9.0' = [
  for vmSetting in vmSettingsList: {
    name: '${vmSetting.vmName}-deployment'
    params: {
      name: vmSetting.vmName
      location: location
      vmSize: vmSize
      imageReference: imageReference
      osType: 'Windows'
      // Explicitly disable encryptionAtHost -- the AVM module version 0.9.0 defaults
      // this to true, which requires the 'Microsoft.Compute/EncryptionAtHost' feature
      // to be enabled on the subscription. Set to false unless the feature is enabled.
      encryptionAtHost: false
      licenseType: 'Windows_Client'
      adminUsername: adminUsername
      adminPassword: adminPassword
      nicConfigurations: [
        {
          nicSuffix: '-nic-01'
          ipConfigurations: [
            {
              name: 'ipconfig01'
              subnetResourceId: subnetResourceId
            }
          ]
        }
      ]
      // Disk configuration (required by AVM)
      osDisk: {
        caching: 'ReadWrite'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      // Pin VMs to an availability zone when availabilityZone > 0, otherwise deploy at regional level.
      zone: availabilityZone
      tags: tags
      // System-assigned managed identity is required by the AADLoginForWindows extension so the
      // VM can acquire an Entra ID token from IMDS during the join process.
      managedIdentities: enableEntraIdJoin
        ? {
            systemAssigned: true
          }
        : null
      // Entra ID join extension (must run before host pool registration)
      extensionAadJoinConfig: enableEntraIdJoin
        ? {
            enabled: true
            tags: tags
          }
        : {
            enabled: false
          }
      // AVD host pool registration: installs the RD Agent and registers the VM
      extensionDSCConfig: {
        enabled: true
        settings: {
          modulesUrl: avdDscModulesUrl
          configurationFunction: 'Configuration.ps1\\AddSessionHost'
          properties: {
            hostPoolName: hostPoolName
            aadJoin: enableEntraIdJoin
            UseAgentDownloadEndpoint: true
            // mdmId: empty string means VMs are not enrolled in Intune MDM.
            // Set to '0000000a-0000-0000-c000-000000000000' to enroll in Intune.
            mdmId: ''
          }
        }
        protectedSettings: {
          properties: {
            registrationInfoToken: hostPoolRegistrationToken
          }
        }
      }
    }
  }
]

// ============================================================================
// Entra ID Login Role Assignments
// ============================================================================
// Grant Entra ID users/groups the VM User Login or VM Admin Login role so they
// can authenticate via Entra ID (RDP sign-in). Assignments are created at the
// resource group scope — the recommended pattern for AVD Entra ID join:
// https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-windows
//
// Role assignments are created here (outside the AVM VM module) to avoid a
// template-schema validation failure in avm/res/compute/virtual-machine:0.9.0
// where roleDefinitionIdOrName is compiled as nullable in the ARM UDT definition,
// causing ARM to reject the template even when a valid value is supplied.

resource entraIdVmRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for assignment in (enableEntraIdJoin ? entraIdLoginRoleAssignments : []): {
    // Stable, idempotent name scoped to (resourceGroup, principalId, roleName).
    name: guid(resourceGroup().id, assignment.principalId, assignment.roleDefinitionIdOrName)
    properties: {
      // Resolve role definition ID: full ARM ID → pass through;
      // well-known friendly name → map to GUID; raw GUID → use directly.
      roleDefinitionId: contains(assignment.roleDefinitionIdOrName, '/')
        ? assignment.roleDefinitionIdOrName
        : subscriptionResourceId(
            'Microsoft.Authorization/roleDefinitions',
            contains(knownRoleDefinitionIds, assignment.roleDefinitionIdOrName)
              ? knownRoleDefinitionIds[assignment.roleDefinitionIdOrName]
              : assignment.roleDefinitionIdOrName
          )
      principalId: assignment.principalId
      // principalType is optional but strongly recommended. Without it, Azure performs an
      // extra graph lookup to infer the type, which can fail for cross-tenant or guest
      // principals. Accepted values: 'User', 'Group', 'ServicePrincipal', 'Device'.
      principalType: assignment.?principalType
    }
  }
]

// ============================================================================
// Outputs
// ============================================================================

@sys.description('Array of deployed session host VM resource IDs.')
output sessionHostResourceIds array = [
  for (vmSetting, i) in vmSettingsList: sessionHostVMs[i].outputs.resourceId
]

@sys.description('Array of deployed session host VM names.')
output sessionHostNames array = [
  for vmSetting in vmSettingsList: vmSetting.vmName
]
