targetScope = 'resourceGroup'

// ============================================================================
// Virtual Network - Azure Virtual Desktop
// Module: avm/res/network/virtual-network
// Deploys a VNet with subnets for AVD infrastructure (session hosts, etc).
// ============================================================================

@sys.description('Required. Location for the Virtual Network. Defaults to resource group location.')
param location string = resourceGroup().location

@sys.description('Required. Name of the Virtual Network.')
param vnetName string

@sys.description('Optional. Address prefix for the Virtual Network (e.g., "10.0.0.0/16").')
param vnetAddressPrefix string = '10.0.0.0/16'

@sys.description('Optional. Name of the AVD session hosts subnet.')
param avdshSubnetName string = 'snet-avdsh'

@sys.description('Optional. Address prefix for the AVD session hosts subnet (e.g., "10.0.1.0/24").')
param avdshSubnetPrefix string = '10.0.1.0/24'

@sys.description('Optional. Array of additional subnets beyond the AVD session hosts subnet.')
param additionalSubnets array = []

@sys.description('Optional. Log Analytics workspace resource ID for VNet diagnostics.')
param logAnalyticsWorkspaceResourceId string = ''

@sys.description('Optional. Tags applied to all VNet resources.')
param tags object = {}

// ============================================================================
// Module Deployment
// ============================================================================

module vnet 'br/public:avm/res/network/virtual-network:0.5.0' = {
  name: '${uniqueString(deployment().name, location)}-vnet'
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: concat(
      [
        {
          name: avdshSubnetName
          addressPrefix: avdshSubnetPrefix
        }
      ],
      additionalSubnets
    )
    diagnosticSettings: !empty(logAnalyticsWorkspaceResourceId)
      ? [
          {
            workspaceResourceId: logAnalyticsWorkspaceResourceId
            logCategoriesAndGroups: [
              {
                categoryGroup: 'allLogs'
              }
            ]
          }
        ]
      : []
    tags: tags
    enableTelemetry: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@sys.description('The resource ID of the deployed Virtual Network.')
output vnetResourceId string = vnet.outputs.resourceId

@sys.description('The name of the deployed Virtual Network.')
output vnetName string = vnet.outputs.name

@sys.description('The resource ID of the AVD session hosts subnet.')
output avdshSubnetResourceId string = '${vnet.outputs.resourceId}/subnets/${avdshSubnetName}'

@sys.description('Array of all subnet resource IDs in the VNet.')
output subnetResourceIds array = vnet.outputs.subnetResourceIds
