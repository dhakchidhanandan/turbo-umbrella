terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "tls_private_key" "turbo-umbrella" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "turbo-umbrella" {
  name     = "turbo-umbrella"
  location = "East US"
}

resource "azurerm_virtual_network" "turbo-umbrella" {
  name                = "turbo-umbrella"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.turbo-umbrella.location
  resource_group_name = azurerm_resource_group.turbo-umbrella.name
}

resource "azurerm_subnet" "turbo-umbrella" {
  name                 = "turbo-umbrella"
  resource_group_name  = azurerm_resource_group.turbo-umbrella.name
  virtual_network_name = azurerm_virtual_network.turbo-umbrella.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "turbo-umbrella" {
  name                = "turbo-umbrella"
  resource_group_name = azurerm_resource_group.turbo-umbrella.name
  location            = azurerm_resource_group.turbo-umbrella.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "turbo-umbrella" {
  name                = "turbo-umbrella"
  location            = azurerm_resource_group.turbo-umbrella.location
  resource_group_name = azurerm_resource_group.turbo-umbrella.name

  security_rule {
    name                       = "All IPv4"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_network_interface" "turbo-umbrella" {
  name                = "turbo-umbrella"
  resource_group_name = azurerm_resource_group.turbo-umbrella.name
  location            = azurerm_resource_group.turbo-umbrella.location

  ip_configuration {
    name                          = "turbo-umbrella"
    subnet_id                     = azurerm_subnet.turbo-umbrella.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.turbo-umbrella.id
  }
}

resource "azurerm_network_interface_security_group_association" "turbo-umbrella" {
  network_interface_id      = azurerm_network_interface.turbo-umbrella.id
  network_security_group_id = azurerm_network_security_group.turbo-umbrella.id
}

resource "azurerm_linux_virtual_machine" "turbo-umbrella" {
  name                = "turbo-umbrella"
  resource_group_name = azurerm_resource_group.turbo-umbrella.name
  location            = azurerm_resource_group.turbo-umbrella.location
  size                = "Standard_B2s"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.turbo-umbrella.id,
  ]
  depends_on = [azurerm_network_interface_security_group_association.turbo-umbrella]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.turbo-umbrella.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "turbo-umbrella"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "local_sensitive_file" "turbo-umbrella" {
  content  = tls_private_key.turbo-umbrella.private_key_openssh
  filename = "turbo-umbrella.pem"
}

output "turbo-umbrella-ip-address" {
  value       = azurerm_linux_virtual_machine.turbo-umbrella.public_ip_address
  description = "ipv4_address"
}
