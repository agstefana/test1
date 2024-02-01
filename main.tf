provider "azurerm" { 
    version = "=1.27.0" 
    
    subscription_id = "a4bac015-e4c3-49b5-a817-ce49c7cbaa5a"
    }

resource "azurerm_resource_group" "adrons_resource_group_workspace" {
  name     = "adrons_workspace"
  location = "West US 2"

  tags = {
    environment = "Development"
  }
}