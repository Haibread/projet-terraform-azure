resource "azurerm_resource_group" "core" {
  name     = "CORE-${var.project-code}-RG"
  location = "West Europe"
}

resource "azurerm_resource_group" "app1" {
  name     = "APP1-${var.project-code}-RG"
  location = "West Europe"
}

resource "azurerm_resource_group" "app2" {
  name     = "APP2-${var.project-code}-RG"
  location = "West Europe"
}

resource "azurerm_resource_group" "shared" {
  name     = "SHARED-${var.project-code}-RG"
  location = "West Europe"
}