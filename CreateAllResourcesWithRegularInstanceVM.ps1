# Create Windows Server 2019 VM - in detail
# https://github.com/Azure/azure-docs-powershell-samples/blob/master/virtual-machine/create-vm-detailed/create-windows-vm-detailed.ps1
# Variables for common values
$resourceGroup = "RG-WinServer2019WithAD"
$location = "canadacentral"
$vmName = "VMWinSrvr2019AD"
$vnetName = "VNet-WinServer2019WithAD"
$subnet1Name = "SNet-WinServer2019WithAD-1"
$subnet2Name = "SNet-WinServer2019WithAD-2"
$pipName = "PIP-WinServer2019WithAD-1"
$nsgRuleRDPName = "NSGRule-WinServer2019WithAD-RDP"
$nsgName = "NSG-WinServer2019WithAD"
$nicName = "NIC-WinServer2019WithAD"
$subnetAddressPrefix1 = "10.0.0.0/24"
$subnetAddressPrefix2 = "10.0.1.0/24"
$vnetAddressPrefix = "10.0.0.0/16"

# Clean up resource group
Remove-AzResourceGroup -Name $resourceGroup

# Create a resource group
New-AzResourceGroup -Name $resourceGroup -Location $location


# Create a subnet configuration
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnetAddressPrefix1
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix $subnetAddressPrefix2

# Create a virtual network
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet1, $subnet2

# Create a public IP address and specify a DNS name
# $pip = New-AzPublicIpAddress -Name "mypublicdns$(Get-Random)" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static -IdleTimeoutInMinutes 4
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Dynamic

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name $nsgRuleRDPName  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup -Location $location -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a virtual machine configuration using Regular instance
$vmConfigRegularInstance = New-AzVMConfig -VMName $vmName -VMSize Standard_D4s_v3 -Priority "Spot" -MaxPrice -1 -EvictionPolicy Deallocate | `
     Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
     Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-datacenter-gensecond -Version latest | `
     Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine either using Regular instance 
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfigRegularInstance