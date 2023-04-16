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

# Security group to allow Core Application gateway to hit port 80 on vm scaleset
resource "azurerm_network_security_group" "app1-nsg" {
  name                = "APP1-${var.project-code}-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.app1.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = azurerm_subnet.core-subnet-alb.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = {
    PROJECT = var.project-code
    ENV     = "APP1"
  }
}

# Add APP1 Scaleset
resource "azurerm_linux_virtual_machine_scale_set" "app1-scaleset" {
  name                = "APP1-${var.project-code}-VMSS"
  location            = var.location
  resource_group_name = azurerm_resource_group.app1.name
  sku                 = "Standard_DS1_v2"
  instances           = 1
  admin_username      = var.admin_username
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
  network_interface {
    name                      = "APP1-${var.project-code}-VMSS-NIC"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.app1-nsg.id
    ip_configuration {
      name      = "APP1-${var.project-code}-VMSS-IPCFG"
      subnet_id = azurerm_subnet.app1-subnet-web.id
      primary   = true
      #application_gateway_backend_address_pool_ids = [
      #  azurerm_application_gateway.alb.backend_address_pool[0].id
      #]
      application_gateway_backend_address_pool_ids = [
        for backend_address_pool in azurerm_application_gateway.alb.backend_address_pool :
        backend_address_pool.id
        if backend_address_pool.name == "ALB-CORE-APP1-${var.project-code}-AGW-BEADDRPOOL"
      ]
    }
  }
  custom_data = data.template_cloudinit_config.install-wordpress.rendered
  tags = {
    PROJECT = var.project-code
    ENV     = "APP1"
  }
}

# Configure cloud-init to install wordpress
data "template_file" "script" {
  template = "${file("./web.tpl")}}"

  vars = {
    WORDPRESS_DB_HOST     = "${azurerm_mysql_server.shared-server.fqdn}"
    WORDPRESS_DB_USER     = "${var.admin_username}@${azurerm_mysql_server.shared-server.name}"
    WORDPRESS_DB_PASSWORD = "${random_password.db-secret.result}"
    WORDPRESS_DB_NAME     = "${azurerm_mysql_database.shared-db.name}"
    WP_HOME               = "http://${azurerm_public_ip.alb-pubip.ip_address}/app1"
    WP_SITEURL            = "http://${azurerm_public_ip.alb-pubip.ip_address}/app1"
  }
}

data "template_cloudinit_config" "install-wordpress" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "web.conf"
    content_type = "text/cloud-config"
    content      = data.template_file.script.rendered
  }

  depends_on = [azurerm_mysql_server.shared-server]
}
