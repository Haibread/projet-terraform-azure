# Storage account for MYSQL DB
resource "azurerm_storage_account" "shared-db-storage-account" {
  name                     = lower("SHARED${var.project-code}SA") # Need lower() because of naming restrictions, and "-" won't work
  location                 = var.location
  resource_group_name      = azurerm_resource_group.shared.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
