# Dns
# Nat Gateway
$subnet01 = New-AzVirtualNetworkSubnetConfig `
    -Name "subnet01" `
    -AddressPrefix "10.0.1.0/24" 

$vnet01 = New-AzVirtualNetwork `
    -Name "vnet01" `
    -ResourceGroupName az700-rg `
    -Location eastus `
    -AddressPrefix "10.0.0.0/16"
    -Subnet $subnet01

# 2. Create a Standard Static Public IP address
$natpip = New-AzPublicIpAddress `
  -Name "natPip" `
  -ResourceGroupName az700-rg `
  -Location eastus `
  -Sku "Standard" `
  -AllocationMethod "Static" `
  -Zone 1

# 3. Create the NAT Gateway
$natgw = New-AzNatGateway `
    -Name "natGw" ` 
    -ResourceGroupName az700-rg `
    -Location eastus `
    -Sku Standard ` 
    -PublicIpAddress $natpip `
    -Zone 1

Set-AzVirtualNetworkSubnetConfig `
    -Name $subnet01.Name `
    -VirtualNetwork $vnet01 `
    -AddressPrefix $subnet01.AddressPrefix `
    -NatGateway $natgw `
$vnet01 | Set-AzVirtualNetwork

Add-AzVirtualNetworkSubnetConfig `
    -Name "subnet02" `
    -VirtualNetwork $vnet01 `
    -AddressPrefix "10.0.2.0/24" `
    -NatGateway $natgw 
$vnet01 | Set-AzVirtualNetwork