# outbound communication
# vnet, subnet, nic, nsg, nsg rules, route table
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



# Remove-AzVirtualNetworkSubnetConfig `
#   -Name <YourSubnetName> `
#   -VirtualNetwork <YourVnetName> | Set-AzVirtualNetwork


$asg = New-AzApplicationSecurityGroup -ResourceGroupName "az700-rg"-Name "asg01" -Location "East US"
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName "az700-rg" -Name "nsg01" -Location "East US"
$asg = Get-AzApplicationSecurityGroup -ResourceGroupName az700-rg
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName az700-rg
$nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-HTTPS-Inbound" `
    -Description "Allow inbound HTTPS traffic" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange "*" `
    -DestinationApplicationSecurityGroup $asg `
    -DestinationPortRange 443

# 4. Update the NSG in Azure to apply the rule
$nsg | Set-AzNetworkSecurityGroup

# 3. Create a Subnet configuration in memory
$subnet01 = New-AzVirtualNetworkSubnetConfig -Name "subnet01" -AddressPrefix "10.0.0.0/24"

# 4. Create the Virtual Network with the Subnet attached
$vnet = New-AzVirtualNetwork -ResourceGroupName az700-rg `
                              -Location eastus `
                             -Name vnet01 `   
                              -AddressPrefix "10.0.0.0/16" `
                              -Subnet $subnet01

# 5. Create the Network Interface Card (NIC) inside the Subnet

$nic01 = New-AzNetworkInterface `
  -Name "nic01" `
  -ResourceGroupName "az700-rg" `
  -Location "eastus" `
  -SubnetId $vnet.Subnets[0].Id `
  -ApplicationSecurityGroupId $asg.Id

# 6. Update the subnet configuration in memory with the NSG
Set-AzVirtualNetworkSubnetConfig `
    -Name $subnet01.Name `
    -VirtualNetwork $vnet `
    -AddressPrefix $subnet01.AddressPrefix `
    -NetworkSecurityGroup $nsg

# 7. Commit the updated configuration back to Azure
$vnet | Set-AzVirtualNetwork

# 8. Vnet Flow Logs
$uniqueName = "az700sa" + (Get-Random -Minimum 10000 -Maximum 99999)

$sa = New-AzStorageAccount `
  -Name $uniqueName `
  -Location eastus `
  -ResourceGroupName az700-rg `
  -SkuName Standard_LRS `
  -Kind StorageV2

$vnet = Get-AzVirtualNetwork -Name vnet01 -ResourceGroupName az700-rg
$nw = Get-AzNetworkWatcher -Location eastus

# Create the VNet Flow Log
 $flowlog01 = New-AzNetworkWatcherFlowLog `
  -Name "vnet01-flowlog" `
  -NetworkWatcherName $nw.Name `
  -ResourceGroupName $nw.ResourceGroupName `
  -TargetResourceId $vnet.Id `
  -StorageId $sa.Id `
  -Enabled $true `
  -FormatVersion 2

# create new network watcher
$nw = New-AzNetworkWatcher `
    -Name "nw" `
    -ResourceGroupName  "az700-rg" `
    -Location "EastUS"

# Test the flow of traffic from a VM to a remote IP address and port
# Test-AzNetworkWatcherIPFlow `
#     -Location $Location `
#     -TargetVirtualMachineId $vm.Id `
#     -TargetNetworkInterfaceId $nicId `
#     -Direction "Inbound" `
#     -Protocol "TCP" `
#     -LocalIPAddress "10.0.0.4" `
#     -LocalPort "80" `
#     -RemoteIPAddress "10.10.10.10" `
#     -RemotePort "60000"
# inbound Test
# Allow-HTTPS-Inbound 100
$nic0 = Get-AzNetworkInterface  
$profile = New-AzNetworkWatcherNetworkConfigurationDiagnosticProfile `
    -Direction "Inbound" `
    -Protocol "TCP" `
    -Source "8.8.8.8" `
    -Destination $nic0.IpConfigurations[0].PrivateIpAddress `
    -DestinationPort "443"

# Run diagnostics directly against the NIC ID
Invoke-AzNetworkWatcherNetworkConfigurationDiagnostic `
    -NetworkWatcher $nw `
    -TargetResourceId $nic.Id `
    -Profile $profile
# outbound Test
# nsg
#  65001 AllowInternetOutBound
$nic0 = Get-AzNetworkInterface
$nw = Get-AzNetworkWatcher  
$profile = New-AzNetworkWatcherNetworkConfigurationDiagnosticProfile `
    -Direction "Outbound" `
    -Protocol "TCP" `
    -Source $nic.IpConfigurations[0].PrivateIpAddress `
    -Destination "8.8.8.8" `
    -DestinationPort "443"

# Run diagnostics directly against the NIC ID
Invoke-AzNetworkWatcherNetworkConfigurationDiagnostic `
    -NetworkWatcher $nw `
    -TargetResourceId $nic.Id `
    -Profile $profile
# not associated to any virtual machine.

# 1. Define the features you want to manage (Connectivity, SecurityAdmin, Routing)
$access = @("connectivity", "securityAdmin", "routing")
# 2. Define the management scope (subscriptions or management groups)
$subId = (Get-AzContext).Subscription.Id
$scope = New-AzNetworkManagerScope -Subscription "/subscriptions/$subId"
# 3. Create the Virtual Network Manager instance
$avnmParams = @{
    Name                      = "az700-vnm"
    ResourceGroupName         = "az700-rg"
    Location                  = "EastUS"
    NetworkManagerScope       = $scope
    NetworkManagerScopeAccess = $access
}
$networkManager = New-AzNetworkManager @avnmParams

$netGroup1 = New-AzNetworkManagerGroup `
  -ResourceGroupName "az700-rg" `
  -NetworkManagerName "az700-vnm" `
  -Name "vnetGroup1" `
  -MemberType "VirtualNetwork"

$netGroup2 = New-AzNetworkManagerGroup `
  -ResourceGroupName "az700-rg" `
  -NetworkManagerName "az700-vnm" `
  -Name "vnetGroup2" `
  -MemberType "VirtualNetwork"

$netGroup3 = New-AzNetworkManagerGroup `
  -ResourceGroupName "az700-rg" `
  -NetworkManagerName "az700-vnm" `
  -Name "vnetGroup3" `
  -MemberType "VirtualNetwork"

$avnmGroupItem1 = New-AzNetworkManagerConnectivityGroupItem `
  -NetworkGroupId $netGroup1.Id `
  -GroupConnectivity DirectlyConnected `
  -IsGlobal 
$avnmGroupItem2 = New-AzNetworkManagerConnectivityGroupItem `
  -NetworkGroupId $netGroup2.Id `
  -GroupConnectivity DirectlyConnected `
  -IsGlobal 
$avnmGroupItem3 = New-AzNetworkManagerConnectivityGroupItem `
  -NetworkGroupId $netGroup3.Id `
  -GroupConnectivity DirectlyConnected `
  -IsGlobal 
$avnmGroup = @($avnmGroupItem1, $avnmGroupItem2, $avnmGroupItem3)
$config = New-AzNetworkManagerConnectivityConfiguration `
 -NetworkManagerName az700-vnm `
  -ConnectivityTopology Mesh `
  -Name fullMesh1 `
  -ResourceGroupName az700-rg `
  -AppliesToGroup $avnmGroup

# deploy the configuration to the network manager
$vnmConnConfig = Get-AzNetworkManagerConnectivityConfiguration `
 -NetworkManagerName az700-vnm `
 -ResourceGroupName az700-rg

Deploy-AzNetworkManagerCommit `
    -Name az700-vnm `
    -ResourceGroupName az700-rg `
    -TargetLocation eastus `
    -ConfigurationId $vnmConnConfig.Id `
    -CommitType "Connectivity"

Remove-AzNetworkManagerConnectivityConfiguration `
    -Name fullMesh1 `
    -NetworkManagerName az700-vnm `
    -ResourceGroupName az700-rg

Remove-AzNetworkManagerGroup `
    -Name vnetGroup1 `
    -NetworkManagerName az700-vnm `
    -ResourceGroupName az700-rg `
    -ForceDelete