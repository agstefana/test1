terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.5.0"
}


# main.tf (vulnerable snip) -- fictitious file for exercise
provider "azurerm" {
features {}
}
resource "azurerm_resource_group" "rg" {
name = "rg-demo-securedata"
location = "Central US"
}
resource "azurerm_network_security_group" "nsg" {
name = "nsg-allow-all-management"
location = azurerm_resource_group.rg.location
resource_group_name = azurerm_resource_group.rg.name
security_rule {
name = "Allow-SSH-RDP-All"
priority = 100
direction = "Inbound"
access = "Allow"
protocol = "*"
source_port_range = "*"
destination_port_range = "22-3389"
source_address_prefix = "0.0.0.0/0"
destination_address_prefix = "*"
}
}
resource "azurerm_virtual_network" "vnet" {
name = "vnet-demo"
address_space = ["10.0.0.0/16"]
location = azurerm_resource_group.rg.location
resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "subnet" {
name = "subnet-demo"
resource_group_name = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.vnet.name
address_prefixes = ["10.0.1.0/24"]
network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_network_interface" "nic" {
name = "nic-vm001"
location = azurerm_resource_group.rg.location
resource_group_name = azurerm_resource_group.rg.name
ip_configuration {
name = "ipconfig1"
subnet_id = azurerm_subnet.subnet.id
private_ip_address_allocation = "Dynamic"
public_ip_address_id = azurerm_public_ip.vm_pip.id
}
}
resource "azurerm_public_ip" "vm_pip" {
name = "pip-vm001"
location = azurerm_resource_group.rg.location
resource_group_name = azurerm_resource_group.rg.name
allocation_method = "Static"
}
resource "azurerm_linux_virtual_machine" "vm" {
name = "vm-demo-app"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location
size = "Standard_B1ms"
admin_username = "devadmin"
network_interface_ids = [azurerm_network_interface.nic.id]
admin_password = "P@ssw0rdDev!!!"
os_disk {
caching = "ReadWrite"
storage_account_type = "Standard_LRS"
}
source_image_reference {
publisher = "Canonical"
offer = "UbuntuServer"
sku = "18.04-LTS"
version = "latest"
}
}
resource "azurerm_sql_server" "sqlsrv" {
name = "sql-demo-server"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location
version = "12.0"
administrator_login = "sqladmin"
administrator_login_password = "SqlAdminPwd!!"
}
resource "azurerm_sql_database" "sqldb" {
name = "sqldb-sensitive"
resource_group_name = azurerm_resource_group.rg.name
server_name = azurerm_sql_server.sqlsrv.name
sku_name = "S0"
}
resource "azurerm_storage_account" "storage" {
name = "stgsecretdemo001"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location
account_tier = "Standard"
account_replication_type = "LRS"
allow_blob_public_access = false
}
output "storage_connection_string" {
value = azurerm_storage_account.storage.primary_connection_string
description = "Connection string"
}
