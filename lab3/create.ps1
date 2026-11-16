# hub and spoke architecture
# Virtual Network
# You will need a specific subnet in your virtual network named `AzureFirewallSubnet`.
# Azure Firewall
# Acts as a barrier between your trusted internal network and untrusted external networks.
# Firewall Policy
# Contains security and operational settings for Azure Firewall.
# For production deployments, use a hub and spoke model,
#  where the firewall is in its own virtual network. 
#  The workload servers are in peered virtual networks in the same region with one or more subnets.
# AzureFirewallSubnet - the firewall is in this subnet.
# Workload1 - the workload server is in this subnet. This subnet's network traffic goes through the firewall.
# Workload2 - the workload server is in this subnet. This subnet's network traffic goes through the firewall.
# User-Defined Routes (UDRs) alone are not enough if traffic passes through Azure Firewall.
#  Azure Firewall blocks all traffic by default, 
#  so you must also create a Network Rule to explicitly allow spoke-to-spoke communication.

# UDRs handle the path. 
# They override Azure's default routing so traffic from Spoke 1 is directed to the firewall's private IP instead of being dropped.
# VNet peering requires forwarded traffic. Both hub-to-spoke peering links must have forwarded traffic enabled so the firewall can send packets across them.
# •Firewall rules handle permission. Once packets arrive at Azure Firewall, 
# its default deny-all posture drops them 
# unless a Network Rule permits the source, destination, ports, and protocols
$location="eastus"
$rg="hubSpoke"

New-AzResourceGroup -Name $rg -Location $location

$hubFwsubnet = New-AzVirtualNetworkSubnetConfig -Name "AzureFirewallSubnet" -AddressPrefix "10.200.1.0/24" 
$hubVnet = New-AzVirtualNetwork -Name "hubVnet" -ResourceGroupName $rg -Location $location -AddressPrefix "10.200.0.0/16" -Subnet $hubFwsubnet

# Get a Public IP for the firewall
$fWPip = New-AzPublicIpAddress `
    -Name "fwPip" `
    -ResourceGroupName $rg `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard
# Create the firewall
$hubFw = New-AzFirewall `
    -Name "hubFw" `
    -ResourceGroupName $rg `
    -Location $location `
    -VirtualNetwork $hubVnet `
    -PublicIpAddress $fWPip


$hubFwPrivIp=$hubFw.IpConfigurations.PrivateIPAddress

Enable Spoke-to-Spoke Routing (UDRs)

Azure VNet peering is non-transitive, meaning Spoke 1 cannot talk to Spoke 2 out of the box. 
To route traffic between spokes and inspect outbound traffic, attach a Route Table to each spoke subnet pointing 0.0.0.0/0 to the private IP of your Hub Firewal
# 0.0.0.0/0 route is for destinations without a more-specific route;
# it generally sends internet-bound traffic through the firewall
# not traffic between peered workload VNets through the firewall.
# create a route table with a default route that points to the firewall, then associate it with the workload subnet:
$rtSpoke1Config = New-AzRouteConfig -Name "rtSpoke1Config"  -AddressPrefix "0.0.0.0/0" -NextHopType "VirtualAppliance" -NextHopIpAddress $hubFwPrivIp
$rtSpoke1 = New-AzRouteTable -Name "rtSpoke1" -ResourceGroupName $rg -Location $location -Route $rtSpoke1Config  -DisableBgpRoutePropagation
$workload1SpokeSubnet = New-AzVirtualNetworkSubnetConfig -Name "workload1SpokeSubnet" -AddressPrefix "10.201.0.0/24"  -RouteTable $rtSpoke1
$workload1SpokeVnet = New-AzVirtualNetwork -Name "workload1SpokeVnet" -ResourceGroupName $rg -Location $location -AddressPrefix "10.201.0.0/16" -Subnet $workload1SpokeSubnet

$hubVnet= Get-AzVirtualNetwork -Name "hubVnet" -ResourceGroupName $rg 
# Bidirectional VNet Peering
# 2. Peer hub to spoke1
Add-AzVirtualNetworkPeering `
  -Name "hub-to-spoke1" `
  -VirtualNetwork $hubVnet `
  -RemoteVirtualNetworkId $workload1SpokeVnet.Id
  -AllowForwardedTraffic $true

# 3. Peer spoke1 to hub
Add-AzVirtualNetworkPeering `
  -Name "spoke1-to-hub" `
  -VirtualNetwork $workload1SpokeVnet `
  -RemoteVirtualNetworkId $hubVnet.Id
  


# create a route table with a default route that points to the firewall, then associate it with the workload subnet:
$rtspoke2Config = New-AzRouteConfig -Name "rtspoke2Config" -AddressPrefix "0.0.0.0/0" -NextHopType "VirtualAppliance" -NextHopIpAddress $hubFwPrivIp
$rtspoke2 = New-AzRouteTable -Name "rtspoke2" -ResourceGroupName $rg -Location $location -Route $rtspoke2Config   -DisableBgpRoutePropagation
$workload2SpokeSubnet =  New-AzVirtualNetworkSubnetConfig -Name "workload2SpokeSubnet" -AddressPrefix "10.202.0.0/24"  -RouteTable $rtSpoke2
$workload2SpokeVnet = New-AzVirtualNetwork -Name "workload2SpokeVnet" -ResourceGroupName $rg -Location $location -AddressPrefix "10.202.0.0/16" -Subnet $workload2SpokeSubnet

# Bidirectional VNet Peering
# 2. Peer hub to spoke2
Add-AzVirtualNetworkPeering `
  -Name "hub-to-spoke2" `
  -VirtualNetwork $hubVnet `
  -RemoteVirtualNetworkId $workload2SpokeVnet.Id
  -AllowForwardedTraffic $true

# 3. Peer spoke2 to hub
Add-AzVirtualNetworkPeering `
  -Name "spoke2-to-hub" `
  -VirtualNetwork $workload2SpokeVnet `
  -RemoteVirtualNetworkId $hubVnet.Id


# 5. Add Azure Firewall Policy Network Rule to Allow Spoke-to-Spoke Traffic
#  Define Network Rules for bidirectional spoke-to-spoke traffic
$workload1SpokeVnet=Get-AzVirtualNetwork -Name "workload1SpokeVnet" -ResourceGroupName $rg
$workload2SpokeVnet=Get-AzVirtualNetwork -Name "workload2SpokeVnet" -ResourceGroupName $rg

$netRule1 = New-AzFirewallNetworkRule `
    -Name "AllowSpoke1ToSpoke2" `
    -Protocol "Any" `
    -SourceAddress  $workload1SpokeVnet.Subnets[0].AddressPrefix `
    -DestinationAddress  $workload2SpokeVnet.Subnets[0].AddressPrefix `
    -DestinationPort *

$netRule2 = New-AzFirewallNetworkRule `
    -Name "AllowSpoke2ToSpoke1" `
    -Protocol "Any" `
    -SourceAddress  $workload2SpokeVnet.Subnets[0].AddressPrefix `
    -DestinationAddress  $workload1SpokeVnet.Subnets[0].AddressPrefix `
    -DestinationPort *

$netRuleCollection = New-AzFirewallNetworkRuleCollection `
    -Name "SpokeToSpokeRuleCollection" `
    -Priority 100 `
    -ActionType "Allow" `
    -Rule $netRule1,$netRule2
$hubFw = Get-AzFirewall -ResourceGroupName $rg -Name "hubFw"
$hubFw.NetworkRuleCollections.Add($netRuleCollection)
Set-AzFirewall -AzureFirewall $hubFw

# Configure an application rule to allow access to www.google.com
# Configure a network rule to allow access to external DNS servers

# Configuring DNS settings on an Azure Network Interface (NIC) allows you to override the default DNS servers assigned at the Virtual Network (VNet) level.

# Resolution Hierarchy

# Azure resolves DNS settings in a specific order:
# 1. NIC-level DNS settings (highest priority; overrides VNet settings)
# 2. Virtual Network (VNet)-level DNS settings (applies to all VMs in the VNet unless overridden by a NIC)
# 3. Azure-provided name resolution (default IP 168.63.129.16)

# How to Configure DNS on an Azure NIC


# Option 1: Azure Portal

# 1. Open the Azure Portal and search for Network interfaces.
# 2. Select the target NIC from the list.
# 3. In the left-hand menu, under Settings, click DNS servers.
# 4. Choose between:
# 	• Inherit from virtual network: Uses the DNS servers configured on the parent VNet (default).
# 	• Custom: Enter your custom DNS server IP addresses manually.
