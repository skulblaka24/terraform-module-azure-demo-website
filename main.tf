terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.76.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#Create Resource Group
resource "azurerm_resource_group" "azure-rg" {
  name     = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-rg"
  location = var.rg_location
  tags = {
    environment = var.app_environment
  }
}

#Create a virtual network
resource "azurerm_virtual_network" "azure-vnet" {
  name                = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-vnet"
  resource_group_name = azurerm_resource_group.azure-rg.name
  location            = var.rg_location
  address_space       = [var.azure_vnet_cidr]
  tags = {
    environment = var.app_environment
  }
}

#Create a subnet
resource "azurerm_subnet" "azure-subnet" {
  name                 = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-subnet"
  resource_group_name  = azurerm_resource_group.azure-rg.name
  virtual_network_name = azurerm_virtual_network.azure-vnet.name
  address_prefixes       = [var.azure_subnet_cidr]
}

#Create Security Group to access Web Server
resource "azurerm_network_security_group" "azure-web-nsg" {
  name                = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-web-nsg"
  location            = azurerm_resource_group.azure-rg.location
  resource_group_name = azurerm_resource_group.azure-rg.name
  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.app_environment
  }
}

#Associate the Web NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "azure-web-nsg-association" {
  subnet_id                 = azurerm_subnet.azure-subnet.id
  network_security_group_id = azurerm_network_security_group.azure-web-nsg.id
}

#Get a Static Public IP
resource "azurerm_public_ip" "azure-web-ip" {
  name                = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-web-ip"
  location            = azurerm_resource_group.azure-rg.location
  resource_group_name = azurerm_resource_group.azure-rg.name
  allocation_method   = "Static"
  tags = {
    environment = var.app_environment
  }
}

#Create Network Card for Web Server VM
resource "azurerm_network_interface" "azure-web-nic" {
  name                      = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-web-nic"
  location                  = azurerm_resource_group.azure-rg.location
  resource_group_name       = azurerm_resource_group.azure-rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure-web-ip.id
  }
  tags = {
    environment = var.app_environment
  }
}

#Create association security group
resource "azurerm_network_interface_security_group_association" "azure-web-nic-sg-ass" {
  network_interface_id      = azurerm_network_interface.azure-web-nic.id
  network_security_group_id = azurerm_network_security_group.azure-web-nsg.id
}

#Create web server vm
resource "azurerm_virtual_machine" "azure-web-vm" {
  name                             = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-web-vm"
  location                         = azurerm_resource_group.azure-rg.location
  resource_group_name              = azurerm_resource_group.azure-rg.name
  network_interface_ids            = [azurerm_network_interface.azure-web-nic.id]
  vm_size                          = var.instance_type
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  storage_image_reference {
    publisher = var.linux-publisher
    offer     = var.linux-offer
    sku       = var.linux-sku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-${var.loc}-${var.app_name}-${var.app_environment}-web-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.linux_vm_hostname
    admin_username = var.linux_admin_user
    admin_password = var.linux_admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = var.app_environment
  }
  # Added to allow destroy to work correctly.
  depends_on = [azurerm_network_interface_security_group_association.azure-web-nic-sg-ass]
}

#Local exec on the VM
resource "null_resource" "configure-azure-web-app" {
  depends_on = [
    azurerm_virtual_machine.azure-web-vm,
  ]

  provisioner "file" {
    source      = "website/"
    destination = "/home/${var.linux_admin_user}"

    connection {
      type     = "ssh"
      user     = var.linux_admin_user
      password = var.linux_admin_password
      host     = azurerm_public_ip.azure-web-ip.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.linux_admin_password} | sudo -S yum -y install httpd",
      "sudo mv /home/${var.linux_admin_user}/* /var/www/html/",
      "sudo echo 'Deploy on the region ${var.rg_location}' >> /var/www/html/index.html",
      "sudo restorecon -R -v /var/www/html/",
      "sudo systemctl start httpd",
      "sudo chown -R apache:apache /var/www/html",
    ]

    connection {
      type     = "ssh"
      user     = var.linux_admin_user
      password = var.linux_admin_password
      host     = azurerm_public_ip.azure-web-ip.ip_address
    }
  }
}
