# ALB Public IP
resource "azurerm_public_ip" "alb-pubip" {
  name                = "ALB-CORE-${var.project-code}-PUBIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "alb" {
  name                = "ALB-CORE-${var.project-code}-AGW"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "ALB-CORE-${var.project-code}-AGW-IPCFG"
    subnet_id = azurerm_subnet.core-subnet-alb.id
  }

  # Front End Configs
  frontend_port {
    name = "ALB-CORE-${var.project-code}-AGW-FEPORT"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "ALB-CORE-${var.project-code}-AGW-FEIPCFG"
    public_ip_address_id = azurerm_public_ip.alb-pubip.id
  }

  # Listerner: HTTP Port 80
  http_listener {
    name                           = "ALB-CORE-${var.project-code}-AGW-HTTPLISTENER"
    frontend_ip_configuration_name = "ALB-CORE-${var.project-code}-AGW-FEIPCFG"
    frontend_port_name             = "ALB-CORE-${var.project-code}-AGW-FEPORT"
    protocol                       = "Http"
  }

  # App1 Backend Configs
  backend_address_pool {
    name = "ALB-CORE-APP1-${var.project-code}-AGW-BEADDRPOOL"
  }
  backend_http_settings {
    name                  = "ALB-CORE-APP1-${var.project-code}-AGW-BEHTTPSETTINGS"
    path                  = "/"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "ALB-CORE-APP1-${var.project-code}-AGW-PROBE"
  }
  probe {
    name                = "ALB-CORE-APP1-${var.project-code}-AGW-PROBE"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
    match { # Optional
      status_code = ["200-399"]
    }
  }


  # App2 Backend Configs
  backend_address_pool {
    name         = "ALB-CORE-APP2-${var.project-code}-AGW-BEADDRPOOL"
    ip_addresses = [azurerm_private_endpoint.app2_wordpress.private_service_connection[0].private_ip_address]
    fqdns        = [azurerm_linux_web_app.app2_wordpress.default_hostname]
  }
  backend_http_settings {
    name                  = "ALB-CORE-APP2-${var.project-code}-AGW-BEHTTPSETTINGS"
    path                  = "/"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "ALB-CORE-APP2-${var.project-code}-AGW-PROBE"
  }
  probe {
    name                = "ALB-CORE-APP2-${var.project-code}-AGW-PROBE"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
    match { # Optional
      status_code = ["200-399"]
    }
  }

  # Path based Routing Rule
  request_routing_rule {
    name               = "ALB-CORE-${var.project-code}-AGW-REQUESTRULE"
    rule_type          = "PathBasedRouting"
    http_listener_name = "ALB-CORE-${var.project-code}-AGW-HTTPLISTENER"
    url_path_map_name  = "ALB-CORE-${var.project-code}-AGW-URLPATHMAP"
    priority           = 1
  }

  # URL Path Map - Define Path based Routing    
  url_path_map {
    name                                = "ALB-CORE-${var.project-code}-AGW-URLPATHMAP"
    default_redirect_configuration_name = "ALB-CORE-${var.project-code}-AGW-REDIRECTCONFIG"
    path_rule {
      name                       = "app1-rule"
      paths                      = ["/app1/*"]
      backend_address_pool_name  = "ALB-CORE-APP1-${var.project-code}-AGW-BEADDRPOOL"
      backend_http_settings_name = "ALB-CORE-APP1-${var.project-code}-AGW-BEHTTPSETTINGS"
    }
    path_rule {
      name                       = "app2-rule"
      paths                      = ["/app2/*"]
      backend_address_pool_name  = "ALB-CORE-APP2-${var.project-code}-AGW-BEADDRPOOL"
      backend_http_settings_name = "ALB-CORE-APP2-${var.project-code}-AGW-BEHTTPSETTINGS"
    }
  }

  # Redirect Config
  redirect_configuration {
    name          = "ALB-CORE-${var.project-code}-AGW-REDIRECTCONFIG"
    redirect_type = "Permanent"
    target_url    = "http://${azurerm_public_ip.alb-pubip.ip_address}/app1/"
  }

  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
}


/* resource "azurerm_application_gateway" "alb" {
  name                = "ALB-CORE-${var.project-code}-AGW"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "ALB-CORE-${var.project-code}-AGW-IPCFG"
    subnet_id = azurerm_subnet.core-subnet-alb.id
  }
  frontend_port {
    name = "ALB-CORE-APP1-${var.project-code}-AGW-FEPORT"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "ALB-CORE-APP1-${var.project-code}-AGW-FEIPCFG"
    public_ip_address_id = azurerm_public_ip.alb-pubip.id
  }
  frontend_port {
    name = "ALB-CORE-APP2-${var.project-code}-AGW-FEPORT"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "ALB-CORE-APP2-${var.project-code}-AGW-FEIPCFG"
    public_ip_address_id = azurerm_public_ip.alb-pubip.id
  }
  backend_address_pool {
    name = "ALB-CORE-APP1-${var.project-code}-AGW-BEADDRPOOL"
    #ip_addresses = azurerm_linux_virtual_machine_scale_set.app1-scaleset.instances.private_ip_address
    # get ip addresses for the scaleset virtual machines from app1
  }
  backend_address_pool {
    name         = "ALB-CORE-APP2-${var.project-code}-AGW-BEADDRPOOL"
    ip_addresses = [azurerm_private_endpoint.app2_wordpress.private_service_connection[0].private_ip_address]
  }
  backend_http_settings {
    name                  = "ALB-CORE-APP1-${var.project-code}-AGW-BEHTTPSETTINGS"
    cookie_based_affinity = "Disabled"
    path                  = "/app1"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 10
  }
  backend_http_settings {
    name                  = "ALB-CORE-APP2-${var.project-code}-AGW-BEHTTPSETTINGS"
    cookie_based_affinity = "Disabled"
    path                  = "/app2"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 10
  }
  http_listener {
    name                           = "ALB-CORE-APP1-${var.project-code}-AGW-HTTPLISTENER"
    frontend_ip_configuration_name = "ALB-CORE-APP1-${var.project-code}-AGW-FEIPCFG"
    frontend_port_name             = "ALB-CORE-APP1-${var.project-code}-AGW-FEPORT"
    protocol                       = "Http"
  }
  http_listener {
    name                           = "ALB-CORE-APP2-${var.project-code}-AGW-HTTPLISTENER"
    frontend_ip_configuration_name = "ALB-CORE-APP2-${var.project-code}-AGW-FEIPCFG"
    frontend_port_name             = "ALB-CORE-APP2-${var.project-code}-AGW-FEPORT"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = "ALB-CORE-APP1-${var.project-code}-AGW-REQUESTRULE"
    rule_type                  = "Basic"
    http_listener_name         = "ALB-CORE-APP1-${var.project-code}-AGW-HTTPLISTENER"
    backend_address_pool_name  = "ALB-CORE-APP1-${var.project-code}-AGW-BEADDRPOOL"
    backend_http_settings_name = "ALB-CORE-APP1-${var.project-code}-AGW-BEHTTPSETTINGS"
  }
  request_routing_rule {
    name                       = "ALB-CORE-APP2-${var.project-code}-AGW-REQUESTRULE"
    rule_type                  = "Basic"
    http_listener_name         = "ALB-CORE-APP2-${var.project-code}-AGW-HTTPLISTENER"
    backend_address_pool_name  = "ALB-CORE-APP2-${var.project-code}-AGW-BEADDRPOOL"
    backend_http_settings_name = "ALB-CORE-APP2-${var.project-code}-AGW-BEHTTPSETTINGS"
  }
  tags = {
    PROJECT = var.project-code
    ENV     = "CORE"
  }
} */

/* # Add app2 to the backend pool
resource "azurerm_application_gateway_backend_address_pool" "app2_pool" {
  name                = "ALB-CORE-APP2-${var.project-code}-AGW-BEADDRPOOL"
  resource_group_name = azurerm_resource_group.example.name
  gateway_name        = azurerm_application_gateway.example.name

  backend_addresses {
    fqdn = azurerm_private_endpoint.app2_wordpress.private_service_connection[0].private_ip_address
  }
}

resource "azurerm_application_gateway_url_path_map" "app2_path_map" {
  name                = "ALB-CORE-APP2-${var.project-code}-AGW-URLPATHMAP"
  resource_group_name = azurerm_resource_group.example.name
  gateway_name        = azurerm_application_gateway.example.name

  default_backend_address_pool_name = azurerm_application_gateway_backend_address_pool.app2_pool.name

  path_rule {
    name        = "app2_rule"
    paths       = ["/app2/*"]
    backend_address_pool_name = azurerm_application_gateway_backend_address_pool.app2_pool.name
  }
} */
