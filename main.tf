terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

# -----------------------
# Resource Group
# -----------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-demo-securedata"
  location = "Central US"
}

# -----------------------
# Network Security Group
# -----------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-allow-all-management"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-RDP-All"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22-3389"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# -----------------------
# Virtual Network and Subnet
# -----------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-demo"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Associate NSG to Subnet (new syntax)
resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------
# Public IP
# -----------------------
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-vm001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# -----------------------
# Network Interface
# -----------------------
resource "azurerm_network_interface" "nic" {
  name                = "nic-vm001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# -----------------------
# Linux Virtual Machine
# -----------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-demo-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = "devadmin"
  admin_password      = "P@ssw0rdDev!!!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

# -----------------------
# Azure SQL Server + DB (modern provider)
# -----------------------
resource "azurerm_mssql_server" "sqlsrv" {
  name                         = "sql-demo-server1234"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = "sqladmin"
  administrator_login_password  = "SqlAdminPwd!!"
}

resource "azurerm_mssql_database" "sqldb" {
  name      = "sqldb-sensitive"
  server_id = azurerm_mssql_server.sqlsrv.id
  sku_name  = "S0"
}

# -----------------------
# Storage Account
# -----------------------
resource "azurerm_storage_account" "storage" {
  name                     = "stgsecretdemo${random_string.rand.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "rand" {
  length  = 4
  upper   = false
  special = false
}

# -----------------------
# Output
# -----------------------
output "storage_connection_string" {
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
  description = "Connection string"
}