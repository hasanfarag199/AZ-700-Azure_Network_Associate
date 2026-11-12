$rg = "rg-lab1"
$location = "uksouth"
$nic = Get-AzNetworkInterface -ResourceGroupName $rg -Name "App-Srv-Nic0"
$vmName = "App-Srv-Vm"
$cred = Get-Credential -UserName "azureuser" -Message "Set the Linux VM credentials"

$cloudInit = @'
#!/bin/bash
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
echo '<h1>App server is running</h1>' > /var/www/html/index.html
systemctl enable --now nginx
'@
$customData = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($cloudInit)
)

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_E2bds_v5"
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux `
    -ComputerName $vmName -Credential $cred -CustomData $customData
$vmConfig = Set-AzVMSourceImage -VM $vmConfig `
    -PublisherName "techlatest" `
    -Offer "desktop-linux" `
    -Skus "ubuntu-gui-linux-22-04" `
    -Version "latest"

$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

    
$vm = New-AzVM -ResourceGroupName $rg -Location $location -VM $vmConfig


# Get-AzSubscription -SubscriptionId "30314159-ed87-435e-928a-e8b23f871383" | Format-List Name, Id, TenantId, State
# Get-AzResourceGroup -Name $rg | Select-Object ResourceGroupName, Location, ProvisioningState
# $vmconfig.NetworkProfile.NetworkInterfaces.Id                 
# Set-AzContext -SubscriptionId "30314159-ed87-435e-928a-e8b23f871383"   
# Get-AzVMImageOffer -Location $location -PublisherName "Canonical" | Select-Object -ExpandProperty Offer
# Get-AzVMImageSku -Location $location -PublisherName "Canonical"  -Offer "0001-com-ubuntu-server-jammy" | Select-Object -ExpandProperty Skus
# MyIP
# (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
# 156.176.135.226
# Remove-AzFirewall -Name "Az-Firewall" -ResourceGroupName "rg-lab1"  -Force   