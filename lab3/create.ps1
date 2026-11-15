# hub and spoke architecture
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


$rtSpoke1Config = New-AzRouteConfig -Name "rtSpoke1Config"  -AddressPrefix "0.0.0.0/0" -NextHopType "VirtualAppliance" -NextHopIpAddress $hubFwPrivIp
$rtSpoke1 = New-AzRouteTable -Name "rtSpoke1" -ResourceGroupName $rg -Location $location -Route $rtSpoke1Config  -DisableBgpRoutePropagation
$workload1SpokeSubnet = New-AzVirtualNetworkSubnetConfig -Name "workload1SpokeSubnet" -AddressPrefix "10.201.0.0/24"  -RouteTable $rtSpoke1
$workload1SpokeVnet = New-AzVirtualNetwork -Name "workload1SpokeVnet" -ResourceGroupName $rg -Location $location -AddressPrefix "10.201.0.0/16" -Subnet $workload1SpokeSubnet

$hubVnet= Get-AzVirtualNetwork -Name "hubVnet" -ResourceGroupName $rg 
# 2. Peer hub to spoke1
Add-AzVirtualNetworkPeering `
  -Name "hub-to-spoke1" `
  -VirtualNetwork $hubVnet `
  -RemoteVirtualNetworkId $workload1SpokeVnet.Id

# 3. Peer spoke1 to hub
Add-AzVirtualNetworkPeering `
  -Name "spoke1-to-hub" `
  -VirtualNetwork $workload1SpokeVnet `
  -RemoteVirtualNetworkId $hubVnet.Id


$rtspoke2Config = New-AzRouteConfig -Name "rtspoke2Config" -AddressPrefix "0.0.0.0/0" -NextHopType "VirtualAppliance" -NextHopIpAddress $hubFwPrivIp
$rtspoke2 = New-AzRouteTable -Name "rtspoke2" -ResourceGroupName $rg -Location $location -Route $rtspoke2Config   -DisableBgpRoutePropagation
$workload2SpokeSubnet =  New-AzVirtualNetworkSubnetConfig -Name "workload2SpokeSubnet" -AddressPrefix "10.202.0.0/24"  -RouteTable $rtSpoke2
$workload2SpokeVnet = New-AzVirtualNetwork -Name "workload2SpokeVnet" -ResourceGroupName $rg -Location $location -AddressPrefix "10.202.0.0/16" -Subnet $workload2SpokeSubnet


# 2. Peer hub to spoke2
Add-AzVirtualNetworkPeering `
  -Name "hub-to-spoke2" `
  -VirtualNetwork $hubVnet `
  -RemoteVirtualNetworkId $workload2SpokeVnet.Id

# 3. Peer spoke2 to hub
Add-AzVirtualNetworkPeering `
  -Name "spoke2-to-hub" `
  -VirtualNetwork $workload2SpokeVnet `
  -RemoteVirtualNetworkId $hubVnet.Id
