# Ubuntu 24.04
## lab1 : Azure resources Connectivity to Internet (egress)
## lab2 : Azure resources Connectivity from Internet (Ingress)
1. Install PowerShell 7.7.0cat :
$ source /etc/os-release
$ wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
$ rm packages-microsoft-prod.deb
$ sudo apt-get update
$ sudo apt-get install -y powershell
2. Install the Azure (Az) PowerShell module:
$ pwsh
$ Install-Module -Name Az -Repository PSGallery -Force
sudo apt update && sudo apt install -y iputils-ping
Test-Connection -TargetName 51.11.156.196 -IPv4

# Diagram
# App-Srv-VM
 #   |
# 10.40.0.10
    |
# # App Subnet
    |
# Route Table
# 0.0.0.0/0 -> 10.40.1.10
 #   |
# Firewall
# 10.40.1.10
#    |
#Internet


# Prequistes
Connect-AzAccount -TenantId "cf8c795b-61fc-47b1-b6d7-ffeda1fb244d" -UseDeviceAuthentication
Get-AzSubscription -TenantId "cf8c795b-61fc-47b1-b6d7-ffeda1fb244d"
Set-AzContext -Subscription "Azure subscription 1"
Get-AzResourceGroup
Get-AzContext 
# Resource Group
$rg = "rg-lab1"
$location = "uksouth"

New-AzResourceGroup `
    -Name $rg `
    -Location $location