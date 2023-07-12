@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Storage Account name.')
param parSaName string

@sys.description('Storage Account type - Premium or Standard.')
param parSaSku string = 'Standard_LRS'

@sys.description('Storage account kind - defaults to V2.')
param parSaKind string = 'StorageV2'

@sys.description('Storage Account access tier - defaults to Hot.')
param parSaTier string = 'Hot'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  sku: {
    name: parSaSku
  }
  kind: parSaKind
  name: parSaName
  location: parLocation
  properties: {
    defaultToOAuthAuthentication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: parSaTier
  }
}
