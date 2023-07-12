@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Virtual Machine Name.')
param parVmName string

@sys.description('The VM SKU to use - use _ instead of spaces.')
param parVmSku string

@sys.description('The local administrator username.')
param parVmLocalAdm string = 'localadm'

@sys.description('The local administrator password.')
@secure()
param parVmPass string

@sys.description('The full Windows OS details.')
param parWindowsVmImage object = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-datacenter-gensecond'
  version: 'latest'
}

@sys.description('Storage type.')
param parVmStorageType string = 'Premium_LRS'

@sys.description('The subnet ID where the VM NIC should be attached.')
param parVmSubnetId string

@sys.description('Diagnostics storage account url.')
param parVmDiagsStorageAccount string

resource vmAvSet 'Microsoft.Compute/availabilitySets@2022-11-01' = {
  name: 'avset-${parVmName}'
  location: parLocation
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: parVmName
  location: parLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    availabilitySet: {
      id: vmAvSet.id
    }
    hardwareProfile: {
      vmSize: parVmSku
    }
    storageProfile: {
      imageReference: parWindowsVmImage
      osDisk: {
        osType: 'Windows'
        name: '${parVmName}-OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: parVmStorageType
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: [
        {
          lun: 0
          name: '${parVmName}-DataDisk_0'
          createOption: 'Attach'
          caching: 'ReadOnly'
          writeAcceleratorEnabled: false
          managedDisk: {
            storageAccountType: parVmStorageType
            id: vmDataDisk.id
          }
          deleteOption: 'Delete'
          diskSizeGB: 32
          toBeDetached: false
        }
      ]
    }
    osProfile: {
      computerName: parVmName
      adminUsername: parVmLocalAdm
      adminPassword: parVmPass
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: (!empty(parVmDiagsStorageAccount)) ? true : false
        storageUri: parVmDiagsStorageAccount
      }
    }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: 'nic01-${parVmName}'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: parVmSubnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
  }
  location: parLocation
}

resource vmDataDisk 'Microsoft.Compute/disks@2022-07-02' = {
  name: '${parVmName}-DataDisk_0'
  location: parLocation
  sku: {
    name: parVmStorageType
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 32
    diskIOPSReadWrite: 120
    diskMBpsReadWrite: 25
    encryption: {
      type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'AllowAll'
    publicNetworkAccess: 'Enabled'
    tier: 'P4'
  }
}
