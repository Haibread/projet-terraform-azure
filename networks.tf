# core-vnet
resource "azurerm_virtual_network" "core-vnet" {
  name                = "${azurerm_resource_group.core.name}-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "core-bastion-subnet"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.core-bastion-vm.id
  }

  subnet {
    name           = "core-alb-subnet"
    address_prefix = "10.0.2.0/24"
  }

  tags = {
    PROJECT = "JTM"
    ENV     = "CORE"
  }
}

resource "azurerm_network_security_group" "core-bastion-vm" {
    name                = "${azurerm_resource_group.core.name}-${var.project-code}-NSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.core.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    tags = {
        PROJECT = "JTM"
        ENV     = "CORE"
    }
}

# app1-vnet
resource "azurerm_virtual_network" "app1-vnet" {
  name                = "${azurerm_resource_group.app1.name}-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.app1.name
  address_space       = ["10.1.0.0/16"]

  subnet {
    name           = "app1-web-subnet"
    address_prefix = "10.1.1.0/24"
  }

  tags = {
    "PROJECT" = "JTM"
    "ENV"     = "APP1"
  }
}

# app2-vnet
resource "azurerm_virtual_network" "app2-vnet" {
  name                = "${azurerm_resource_group.app2.name}-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.app2.name
  address_space       = ["10.2.0.0/16"]

  subnet {
    name           = "app2-web-subnet"
    address_prefix = "10.2.1.0/24"
  }
  tags = {
    "PROJECT" = "JTM"
    "ENV"     = "APP2"
  }
}

# shared-vnet
resource "azurerm_virtual_network" "shared-vnet" {
  name                = "${azurerm_resource_group.shared.name}-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.shared.name
  address_space       = ["10.3.0.0/16"]

  subnet {
    name           = "shared-db-subnet"
    address_prefix = "10.3.1.0/24"
  }
  tags = {
    "PROJECT" = "JTM"
    "ENV"     = "SHARED"
  }
}
