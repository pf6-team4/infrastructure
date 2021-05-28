terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
   #for remote
  backend "remote" {
    organization = "pleianthos"
    workspaces {
      name = "Team4"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_appId
  client_secret   = var.client_password
  tenant_id       = var.tenant_id
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-TM4"
  location = var.location
  tags     = var.tags
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}TFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Create subnet in the existing virtual network
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}TFSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}TFPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

# Create Network Security Group and rule
# Network Security Groups control the flow of network traffic in and out of your VM.
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}TFNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
# A virtual network interface card (NIC) connects your VM to a given virtual network, 
# public IP address, and network security group. 
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}NIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}NICConfg"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}


# Add public key 
# resource "azurerm_ssh_public_key" "main" {
#    name                = azurerm_ssh_public_key.main.name
#    resource_group_name = azurerm_ssh_public_key.main.resource_group_name
#    location            = var.location
#    public_key          = file("/home/ip/Downloads/Porject_key.pem")
# }


# Create a Linux virtual machine and instal jenkins, maven and Ansible in the VM
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}TFVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"
  tags                  = var.tags

  storage_os_disk {
    name              = "${var.prefix}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}TFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "remote-exec" { 
  inline=[
          "sudo wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
          "sudo apt-add-repository 'deb https://pkg.jenkins.io/debian-stable binary/'",
          "sudo apt-get -q update",
          "sudo apt-get -y install jenkins",
          "sudo apt-get install -y maven",
          "sudo apt install -y software-properties-common",
          "sudo add-apt-repository --yes --update ppa:ansible/ansible",
          "sudo apt-get -q update",
          "sudo apt install -y ansible",
  ]
    connection {
              type     = "ssh"
              user     = "${var.admin_username}"
              password = "${var.admin_password}"
              host     = azurerm_public_ip.main.name
    }
  }
}

#data source
data "azurerm_public_ip" "main" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_virtual_machine.main.resource_group_name
  depends_on          = [azurerm_virtual_machine.main]
}

output "os_sku" {
  value = lookup(var.sku, var.location)
}

output "public_ip_address" {
  value = data.azurerm_public_ip.main.ip_address
}