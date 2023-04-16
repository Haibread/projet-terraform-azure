# core-vnet
resource "azurerm_virtual_network" "core-vnet" {
  name                = "CORE-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}

resource "azurerm_subnet" "core-subnet-bastion" {
  name                 = "BASTION-CORE-${var.project-code}-SUBNET"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "core-subnet-bastion-nsg" {
  subnet_id                 = azurerm_subnet.core-subnet-bastion.id
  network_security_group_id = azurerm_network_security_group.core-bastion-vm.id
}

resource "azurerm_subnet" "core-subnet-alb" {
  name                 = "ALB-CORE-${var.project-code}-SUBNET"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "core-bastion-vm" {
  name                = "CORE-${var.project-code}-NSG"
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
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}

# app1-vnet
resource "azurerm_virtual_network" "app1-vnet" {
  name                = "APP1-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.app1.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    "PROJECT" = "JTM"
    "ENV"     = "APP1"
  }
}

resource "azurerm_subnet" "app1-subnet-web" {
  name                 = "VMSS-APP1-${var.project-code}-SUBNET"
  resource_group_name  = azurerm_resource_group.app1.name
  virtual_network_name = azurerm_virtual_network.app1-vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# app2-vnet
resource "azurerm_virtual_network" "app2-vnet" {
  name                = "APP2-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.app2.name
  address_space       = ["10.2.0.0/16"]
  tags = {
    "PROJECT" = var.project-code
    "ENV"     = "APP2"
  }
}

resource "azurerm_subnet" "app2-subnet-web" {
  name                 = "APP-APP2-${var.project-code}-SUBNET"
  resource_group_name  = azurerm_resource_group.app2.name
  virtual_network_name = azurerm_virtual_network.app2-vnet.name
  address_prefixes     = ["10.2.1.0/24"] /* 
  delegation { # Delegation is needed in order to create a web app in this subnet
    name = "web-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  } */
}

# shared-vnet
resource "azurerm_virtual_network" "shared-vnet" {
  name                = "SHARED-${var.project-code}-VNET"
  location            = var.location
  resource_group_name = azurerm_resource_group.shared.name
  address_space       = ["10.3.0.0/16"]
  tags = {
    "PROJECT" = var.project-code
    "ENV"     = "SHARED"
  }
}

resource "azurerm_subnet" "shared-subnet-web" {
  name                 = "DB-SHARED-${var.project-code}-SUBNET"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.shared-vnet.name
  address_prefixes     = ["10.3.1.0/24"]
}

# Setup peerings
resource "azurerm_virtual_network_peering" "core-to-app1" {
  name                         = "CORE-APP1-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.core.name
  virtual_network_name         = azurerm_virtual_network.core-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.app1-vnet.id
  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "app1-to-core" {
  name                         = "APP1-CORE-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.app1.name
  virtual_network_name         = azurerm_virtual_network.app1-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.core-vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "core-to-app2" {
  name                         = "CORE-APP2-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.core.name
  virtual_network_name         = azurerm_virtual_network.core-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.app2-vnet.id
  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "app2-to-core" {
  name                         = "APP2-CORE-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.app2.name
  virtual_network_name         = azurerm_virtual_network.app2-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.core-vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "shared-to-app1" {
  name                         = "SHARED-APP1-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.shared.name
  virtual_network_name         = azurerm_virtual_network.shared-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.app1-vnet.id
  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "app1-to-shared" {
  name                         = "APP1-SHARED-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.app1.name
  virtual_network_name         = azurerm_virtual_network.app1-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.shared-vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "shared-to-app2" {
  name                         = "SHARED-APP2-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.shared.name
  virtual_network_name         = azurerm_virtual_network.shared-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.app2-vnet.id
  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "app2-to-shared" {
  name                         = "APP2-SHARED-${var.project-code}-PEERING"
  resource_group_name          = azurerm_resource_group.app2.name
  virtual_network_name         = azurerm_virtual_network.app2-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.shared-vnet.id
  allow_virtual_network_access = true
}