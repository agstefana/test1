terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.56.0"
    }
  }
}

provider "azurerm" { 
    version = "=2.56.0" 
       features {}

    }

resource "azurerm_resource_group" "adrons_resource_group_workspace" {
  name     = "adrons_workspace"
  location = "West US 2"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_virtual_network" "exampleVNET" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.adrons_resource_group_workspace.location
  resource_group_name = azurerm_resource_group.adrons_resource_group_workspace.name
}

resource "azurerm_firewall" "exampleFW" {
  name                = "example-firewall"
  resource_group_name = azurerm_resource_group.adrons_resource_group_workspace.name
  location            = azurerm_resource_group.adrons_resource_group_workspace.location
  sku_name            = "azfw_hub_1.0.0"
}