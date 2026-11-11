# inbonud communication
Connect-AzAccount -TenantId "cf8c795b-61fc-47b1-b6d7-ffeda1fb244d" -UseDeviceAuthentication
$rg = "rg-lab1"
$location = "uksouth"
$appSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name "AppSubnet" `
    -AddressPrefix "10.40.0.0/24"
$App-Srv-Nic0 = New-AzNetworkInterface `
    -Name "App-Srv-Nic0" `
    -ResourceGroupName $rg `
    -Location $location `
    -SubnetId $appSubnet.Id `
    -PrivateIpAddress "10.40.0.10"

$appVmPip = New-AzPublicIpAddress  `
    -Name "App-Srv-Vm-Pip" `
    -ResourceGroupName $rg `
    -Location $location  `
    -AllocationMethod Static `
    -Sku Standard

# associate IP to nic
$ipconfig=$App-Srv-Nic0.IpConfigurations.Name
$App-Srv-Nic0 | Set-AzNetworkInterfaceIpConfig -PublicIpAddress $appVmPip -Name $ipconfig
$App-Srv-Nic0 | Set-AzNetworkInterface