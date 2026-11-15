# Create the NIC
$wsn = Get-AzVirtualNetworkSubnetConfig `
    -Name Workload-SN `
    -VirtualNetwork $testVnet
$NIC01 = New-AzNetworkInterface `
    -Name Srv-Work `
    -ResourceGroupName Test-FW-RG `
    -Location "East US" `
    -Subnet $wsn

# Define the virtual machine
$SecurePassword = ConvertTo-SecureString "<choose a password>" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("<choose a user name>", $SecurePassword);
$VirtualMachine = New-AzVMConfig `
    -VMName Srv-Work `
    -VMSize "Standard_DS2"
$VirtualMachine = Set-AzVMOperatingSystem `
    -VM $VirtualMachine `
    -Windows `
    -ComputerName Srv-Work `
    -ProvisionVMAgent `
    -EnableAutoUpdate `
    -Credential $Credential
$VirtualMachine = Add-AzVMNetworkInterface `
    -VM $VirtualMachine `
    -Id $NIC01.Id
$VirtualMachine = Set-AzVMSourceImage `
    -VM $VirtualMachine `
    -PublisherName 'MicrosoftWindowsServer' `
    -Offer 'WindowsServer' `
    -Skus '2019-Datacenter' `
    -Version latest

# Create the virtual machine
New-AzVM `
    -ResourceGroupName Test-FW-RG `
    -Location "East US" `
    -VM $VirtualMachine `
    -Verbose

    # VMSS