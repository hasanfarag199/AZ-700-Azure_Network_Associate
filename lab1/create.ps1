# outbound communication
$rg = "rg-lab1"
$location = "uksouth"

# VNet and Subnets
$appSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name "AppSubnet" `
    -AddressPrefix "10.40.0.0/24"

$secSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name "SecSubnet" `
    -AddressPrefix "10.40.1.0/24"

$vnet = New-AzVirtualNetwork `
    -Name "Az-UkSth-Vnet" `
    -ResourceGroupName $rg `
    -Location $location `
    -AddressPrefix "10.40.0.0/16" `
    -Subnet $appSubnet,$secSubnet

# $nsg = New-AzNetworkSecurityGroup `
#     -Name "App-NSG" `
#     -ResourceGroupName $rg `
#     -Location $location

# Add-AzNetworkSecurityRuleConfig `
#     -NetworkSecurityGroup $nsg `
#     -Name "Deny-Internet-Egress" `
#     -Direction Outbound `
#     -Priority 100 `
#     -Access Deny `
#     -Protocol * `
#     -SourceAddressPrefix "10.40.0.0/24" `
#     -SourcePortRange * `
#     -DestinationAddressPrefix Internet `
#     -DestinationPortRange *

# $nsg | Set-AzNetworkSecurityGroup


# $appSubnet = Get-AzVirtualNetworkSubnetConfig `
#     -Name "AppSubnet" `
#     -VirtualNetwork $vnet

# $appSubnet.NetworkSecurityGroup = $nsg

# $vnet | Set-AzVirtualNetwork


$rt = New-AzRouteTable `
    -Name "App-RT" `
    -ResourceGroupName $rg `
    -Location $location

Add-AzRouteConfig `
    -Name "DefaultRouteToFirewall" `
    -AddressPrefix "0.0.0.0/0" `
    -NextHopType VirtualAppliance `
    -NextHopIpAddress "10.40.1.10" `
    -RouteTable $rt

$rt | Set-AzRouteTable


$appSubnet = Get-AzVirtualNetworkSubnetConfig `
    -Name "AppSubnet" `
    -VirtualNetwork $vnet

$appSubnet.RouteTable = $rt

$vnet | Set-AzVirtualNetwork

# $appSubnet = Get-AzVirtualNetworkSubnetConfig `
#     -Name "AppSubnet" `
#     -VirtualNetwork $vnet

# $secSubnet = Get-AzVirtualNetworkSubnetConfig `
#     -Name "SecSubnet" `
#     -VirtualNetwork $vnet

# New-AzNetworkInterface `
#     -Name "App-Srv-Nic0" `
#     -ResourceGroupName $rg `
#     -Location $location `
#     -SubnetId $appSubnet.Id `
#     -PrivateIpAddress "10.40.0.10"

# New-AzNetworkInterface `
#     -Name "Fw-Nic1" `
#     -ResourceGroupName $rg `
#     -Location $location `
#     -SubnetId $secSubnet.Id `
#     -PrivateIpAddress "10.40.1.10"

$vnet = Get-AzVirtualNetwork -Name Az-UkSth-Vnet -ResourceGroupName $rg       

$vnet.Subnets | Select-Object Name, AddressPrefix  

Add-AzVirtualNetworkSubnetConfig `
    -Name "AzureFirewallSubnet" `
    -AddressPrefix "10.40.2.0/26" `
    -VirtualNetwork $vnet    

Add-AzVirtualNetworkSubnetConfig `
    -Name "azureFirewallMgmtSubnet" `
    -AddressPrefix "10.40.3.0/26" `
    -VirtualNetwork $vnet

Remove-AzVirtualNetworkSubnetConfig `
  -Name <YourSubnetName> `
  -VirtualNetwork <YourVnetName> | Set-AzVirtualNetwork


$vnet | Set-AzVirtualNetwork  

$firewallPublicIp = New-AzPublicIpAddress `
    -Name "Az-Fw-PIP" `
    -ResourceGroupName $rg `
    -Location $location `
    -AllocationMethod Static  `
    -Sku Standard

$firewallMgmtPublicIp = New-AzPublicIpAddress `
    -Name "Az-Fw-Mgmt-Pip"  `
    -ResourceGroupName $rg `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard

$firewall = New-AzFirewall `
    -Name "Az-Firewall" `
    -ResourceGroupName $rg `
    -Location $location `
    -VirtualNetwork $vnet `
    -PublicIpAddress $firewallPublicIp `
    -ManagementPublicIpAddress $firewallMgmtPublicIp 


