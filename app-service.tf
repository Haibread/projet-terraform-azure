resource "azurerm_service_plan" "app2_service_plan" {
  name                = "APP2-${var.project-code}-SERVICEPLAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.app2.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app2_wordpress" {
  name                = "APP2-${var.project-code}-WORDPRESS"
  location            = var.location
  resource_group_name = azurerm_resource_group.app2.name
  service_plan_id     = azurerm_service_plan.app2_service_plan.id
  #virtual_network_subnet_id = azurerm_subnet.app2-subnet-web.id
  site_config {
    always_on = true
    application_stack {
      docker_image     = "wordpress"
      docker_image_tag = "latest"
    }
  }
  app_settings = {
    WORDPRESS_DB_HOST      = "${azurerm_mysql_server.shared-server.fqdn}"
    WORDPRESS_DB_USER      = "${var.admin_username}@${azurerm_mysql_server.shared-server.name}"
    WORDPRESS_DB_PASSWORD  = "${random_password.db-secret.result}"
    WORDPRESS_DB_NAME      = "${azurerm_mysql_database.shared-db.name}"
    WORDPRESS_CONFIG_EXTRA = "define('WP_HOME','http://${azurerm_public_ip.alb-pubip.ip_address}/app2/');define('WP_SITEURL','http://${azurerm_public_ip.alb-pubip.ip_address}/app2/');"
  }
}

# Private endpoint for web app in subnet app2-subnet-web
resource "azurerm_private_endpoint" "app2_wordpress" {
  name                = "APP2-${var.project-code}-PRIVATEENDPOINT"
  location            = var.location
  resource_group_name = azurerm_resource_group.app2.name
  subnet_id           = azurerm_subnet.app2-subnet-web.id
  private_service_connection {
    name                           = "APP2-${var.project-code}-PRIVATEENDPOINT-CONNECTION"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.app2_wordpress.id
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.app2_wordpress.id]
  }
}

# Private DNS zone for web app in subnet app2-subnet-web
resource "azurerm_private_dns_zone" "app2_wordpress" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.app2.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app2_wordpress" {
  name                  = "APP2-${var.project-code}-PRIVATEDNSZONE-VNETLINK"
  resource_group_name   = azurerm_resource_group.app2.name
  private_dns_zone_name = azurerm_private_dns_zone.app2_wordpress.name
  virtual_network_id    = azurerm_virtual_network.app2-vnet.id
}

# Access DNS zone for the core virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "core_vnet" {
  name                  = "CORE-${var.project-code}-PRIVATEDNSZONE-VNETLINK"
  resource_group_name   = azurerm_resource_group.app2.name
  private_dns_zone_name = azurerm_private_dns_zone.app2_wordpress.name
  virtual_network_id    = azurerm_virtual_network.core-vnet.id
}
resource "azurerm_private_dns_cname_record" "app2" {
  name                = "app2-jtm-wordpress.privatelink.azurewebsites.net"
  record              = "app2-jtm-wordpress.azurewebsites.net"
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.app2_wordpress.name
  resource_group_name = azurerm_resource_group.app2.name
}
