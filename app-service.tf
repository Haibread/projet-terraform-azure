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
    WORDPRESS_DB_HOST     = "${azurerm_mysql_server.shared-server.fqdn}"
    WORDPRESS_DB_USER     = "${var.admin_username}@${azurerm_mysql_server.shared-server.name}"
    WORDPRESS_DB_PASSWORD = "${random_password.db-secret.result}"
    WORDPRESS_DB_NAME     = "${azurerm_mysql_database.shared-db.name}"
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
}