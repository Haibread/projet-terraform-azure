# Bastion VM
# Public IP
resource "azurerm_public_ip" "bastion-pubip" {
  name                = "bastion-pubip"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name

  allocation_method = "Static"

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}

# NIC
resource "azurerm_network_interface" "bastion-nic" {
  name                = "BASTION-CORE-${var.project-code}-NIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name

  ip_configuration {
    name                          = "BASTION-CORE-${var.project-code}-PUBIP"
    subnet_id                     = azurerm_subnet.core-subnet-bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion-pubip.id
  }

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}

# VM
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "BASTION-CORE-${var.project-code}-VM"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  size                = "Standard_D2s_v3"
  priority            = "Spot"
  eviction_policy     = "Deallocate"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.bastion-nic.id
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_pubkey
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }

}
