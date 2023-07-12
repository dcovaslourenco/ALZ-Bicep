@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Local Network Gateway name.')
param parLngName string

@sys.description('Local Network Gateway gateway IP address.')
param parLngPip string

@sys.description('Local Network Gateway address spaces.')
param parLngAddressRanges array = [
  '172.20.1.0/24'
  '172.20.2.0/24'
]

@sys.description('Connection name.')
param parConnName string

@sys.description('VPN Gateway name.')
param parVpnGwResourceId string

@sys.description('Connection name.')
param parConnSharedKey string

resource lng 'Microsoft.Network/localNetworkGateways@2022-07-01' = {
  name: parLngName
  location: parLocation
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: parLngAddressRanges
    }
    gatewayIpAddress: parLngPip
  }
}

resource connection 'Microsoft.Network/connections@2022-07-01' = {
  name: parConnName
  location: parLocation
  properties: {
    virtualNetworkGateway1: {
      id: parVpnGwResourceId
    }
    localNetworkGateway2: {
      id: lng.id
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: parConnSharedKey
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
    gatewayCustomBgpIpAddresses: []
  }
}
