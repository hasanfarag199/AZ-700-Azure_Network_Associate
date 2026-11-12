# inbonud communication
# load balancer (backend pool and NAT), firewall, application gateway 
Connect-AzAccount -TenantId "cf8c795b-61fc-47b1-b6d7-ffeda1fb244d" -UseDeviceAuthentication
$rg = "rg-lab1"
$location = "uksouth"
$vnet = Get-AzVirtualNetwork -Name "Az-UkSth-Vnet" -ResourceGroupName $rg
$appSubnet = Get-AzVirtualNetworkSubnetConfig -Name "AppSubnet" -VirtualNetwork $vnet
$appSrvNic0 = New-AzNetworkInterface `
    -Name "App-Srv-Nic0" `
    -ResourceGroupName $rg `
    -Location $location `
    -SubnetId $appSubnet.Id `
    -PrivateIpAddress "10.40.0.10"
# 1. public Ip address
$appVmPip = New-AzPublicIpAddress  `
    -Name "App-Srv-Vm-Pip" `
    -ResourceGroupName $rg `
    -Location $location  `
    -AllocationMethod Static `
    -Sku Standard

# associate IP to nic
$ipconfig = $appSrvNic0.IpConfigurations.Name
$appSrvNic0 | Set-AzNetworkInterfaceIpConfig -PublicIpAddress $appVmPip -Name $ipconfig
$appSrvNic0 | Set-AzNetworkInterface

# 2. Public Load Balancer (L4)
$lbPublicIp = New-AzPublicIpAddress `
    -Name "App-Srv-Lb-Pip" `
    -ResourceGroupName $rg `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard

$frontendIp = New-AzLoadBalancerFrontendIpConfig `
    -Name "loadBalancerFrontIp" `
    -PublicIpAddress $lbPublicIp
$backendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "lbBackendPool"
$healthProbe = New-AzLoadBalancerProbeConfig `
    -Name "lbHealthProbe" `
    -Protocol Http `
    -Port 80 `
    -RequestPath "/" `
    -IntervalInSeconds 15 `
    -ProbeCount 2

$lbRule = New-AzLoadBalancerRuleConfig `
    -Name "http" `
    -FrontendIpConfiguration $frontendIp `
    -BackendAddressPool $backendPool `
    -Probe $healthProbe `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 80


$lb = New-AzLoadBalancer `
    -ResourceGroupName $rg `
    -Name "publicAppSrvLb" `
    -Location $location `
    -Sku Standard `
    -FrontendIpConfiguration $frontendIp `
    -BackendAddressPool $backendPool `
    -Probe $healthProbe `
    -LoadBalancingRule $lbRule
$appSrvNic0 = Get-AzNetworkInterface -ResourceGroupName $rg -Name "App-Srv-Nic0"
$ipconfig = $appSrvNic0.IpConfigurations.Name
$lbAddrPool = $lb.BackendAddressPools[0]
# Add the NIC's IP configuration to the load balancer backend pool.
$appSrvNic0 | Set-AzNetworkInterfaceIpConfig `
    -LoadBalancerBackendAddressPool $lbAddrPool `
    -Name $ipconfig
$appSrvNic0 | Set-AzNetworkInterface
# Or instead of multi instances, direct to specific instance with NAT
# 2.b New-AzLoadBalancerInboundNatRuleConfig
$lbPublicIpNat = New-AzPublicIpAddress `
    -Name "AppSrvLbPipNat" `
    -ResourceGroupName $rg `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard

$frontendIpNat = New-AzLoadBalancerFrontendIpConfig `
    -Name "loadBalancerFrontIpNat" `
    -PublicIpAddress $lbPublicIpNat

$inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig `
                    -Name "httpToAppSrv" `
                    -FrontendIpConfiguration $frontendIpNat `
                    -Protocol Tcp `
                    -FrontendPort 80 `
                    -BackendPort 80
$lbNat = New-AzLoadBalancer `
            -Name "publicAppSrvLbNat" `
            -InboundNatRule $inboundNatRule `
            -FrontendIpConfiguration $frontendIpNat `
            -Sku Standard `
            -Location $location `
            -ResourceGroupName $rg
$appSrvNic0 = Get-AzNetworkInterface -ResourceGroupName $rg -Name "App-Srv-Nic0"
$lbNatRule = $lbNat.InboundNatRules[0]
$appSrvNic0IpConfig = $appSrvNic0.IpConfigurations[0].Name
$appSrvNic0 | Set-AzNetworkInterfaceIpConfig -LoadBalancerInboundNatRule $lbNatRule -Name $appSrvNic0IpConfig
$appSrvNic0 | Set-AzNetworkInterface
$appSrvNic0.IpConfigurations[0].LoadBalancerInboundNatRules | Select-Object Name, Id
# 3. Azure Firewall (outbound tls inspection L4-L7, for inbound use app gw )
$vnet = Get-AzVirtualNetwork -Name Az-UkSth-Vnet -ResourceGroupName $rg       

Add-AzVirtualNetworkSubnetConfig `
    -Name "AzureFirewallSubnet" `
    -AddressPrefix "10.40.2.0/26" `
    -VirtualNetwork $vnet    

Add-AzVirtualNetworkSubnetConfig `
    -Name "azureFirewallMgmtSubnet" `
    -AddressPrefix "10.40.3.0/26" `
    -VirtualNetwork $vnet

$vnet | Set-AzVirtualNetwork  

$vnet.Subnets | Select-Object Name, AddressPrefix  

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

# 4. Application Gateway (L7 lB and inbound tls inspection)
$rg = "ag-rg"
$location="eastus"
New-AzResourceGroup -Name $rg -Location $location
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.1.0/24

$agSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name myAGSubnet -AddressPrefix 10.0.2.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName myResourceGroupAG -Location eastus -Name myVNet -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnetConfig, $agSubnetConfig

$pip = New-AzPublicIpAddress -ResourceGroupName myResourceGroupAG -Location eastus -Name myAGPublicIPAddress -AllocationMethod Static -Sku Standard
$vnet = Get-AzVirtualNetwork -ResourceGroupName myResourceGroupAG -Name myVNet

$subnet=$vnet.Subnets[1]

$gipconfig = New-AzApplicationGatewayIPConfiguration -Name myAGIPConfig -Subnet $subnet

$fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name myAGFrontendIPConfig -PublicIPAddress $pip

$frontendport = New-AzApplicationGatewayFrontendPort -Name myFrontendPort -Port 80

$defaultPool = New-AzApplicationGatewayBackendAddressPool `
  -Name appGatewayBackendPool

$poolSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name myPoolSettings `
  -Port 80 `
  -Protocol Http `
  -CookieBasedAffinity Enabled `
  -RequestTimeout 120

$defaultlistener = New-AzApplicationGatewayHttpListener `
  -Name mydefaultListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport

$frontendRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name rule1 `
  -RuleType Basic `
  -Priority 1000 `
  -HttpListener $defaultlistener `
  -BackendAddressPool $defaultPool `
  -BackendHttpSettings $poolSettings

$sku = New-AzApplicationGatewaySku `
  -Name WAF_v2 `
  -Tier WAF_v2 `
  -Capacity 2

$policySetting = New-AzApplicationGatewayFirewallPolicySetting `
   -Mode Prevention -State Enabled `
   -MaxRequestBodySizeInKb 100 -MaxFileUploadInMb 256

$wafPolicy = New-AzApplicationGatewayFirewallPolicy -Name wafpolicyNew -ResourceGroup myResourceGroupAG `
   -Location $location -PolicySetting $PolicySetting

$appgw = New-AzApplicationGateway `
  -Name myAppGateway `
  -ResourceGroupName myResourceGroupAG `
  -Location eastus `
  -BackendAddressPools $defaultPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendport `
  -HttpListeners $defaultlistener `
  -RequestRoutingRules $frontendRule `
  -Sku $sku `
  -FirewallPolicy $wafPolicy

  # hub and spoke architecture