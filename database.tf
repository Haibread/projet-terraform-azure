# Random password
resource "random_password" "db-secret" {
  length  = 24
  special = false
}

# Server
resource "azurerm_mysql_server" "shared-server" {
  name                         = lower("DBServer-SHARED-${var.project-code}-DBServer") # Need lower() because of naming restrictions
  location                     = var.location
  resource_group_name          = azurerm_resource_group.shared.name
  administrator_login          = var.admin_username
  administrator_login_password = random_password.db-secret.result

  sku_name   = "B_Gen5_1"
  storage_mb = 5120
  version    = "8.0"

  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

# DB
resource "azurerm_mysql_database" "shared-db" {
  #name                = "DB-SHARED-${var.project-code}-DB"
  name                = "wordpress"
  resource_group_name = azurerm_resource_group.shared.name
  server_name         = azurerm_mysql_server.shared-server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# Allow access from app service
/* locals {
  func_ips = distinct(flatten([split(",", azurerm_linux_web_app.app2_wordpress.possible_outbound_ip_addresses)])) # Get all possible outbound IP addresses from app service
}

resource "azurerm_mysql_firewall_rule" "app2-wordpress" {
  for_each = toset(local.func_ips)

  name                = "APP2-SHARED-${replace(each.value, ".", "_")}-${var.project-code}-FWRULE"
  resource_group_name = azurerm_resource_group.shared.name
  server_name         = azurerm_mysql_server.shared-server.name
  start_ip_address    = each.value
  end_ip_address      = each.value
} */

resource "azurerm_mysql_firewall_rule" "app2-wordpress" {
  name                = "APP2-SHARED-${var.project-code}-FWRULE"
  resource_group_name = azurerm_resource_group.shared.name
  server_name         = azurerm_mysql_server.shared-server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
