# Ubuntu 24.04
## lab1 : Azure resources Connectivity to Internet (egress)
## lab2 : Azure resources Connectivity from Internet (Ingress)
1. Install PowerShell 7.6.9:
$ source /etc/os-release
$ wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
$ rm packages-microsoft-prod.deb
$ sudo apt-get update
$ sudo apt-get install -y powershell
2. Install the Azure (Az) PowerShell module:
$ pwsh
$ Install-Module -Name Az -Repository PSGallery -Force