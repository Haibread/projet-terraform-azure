# Create SSH pub key for future use
resource "azurerm_ssh_public_key" "core-admin_ssh_pubkey" {
    name = "ADMIN-CORE-${var.project-code}-SSHPUBKEY"
    resource_group_name = azurerm_resource_group.core.name
    location = var.location
    public_key = var.admin_ssh_pubkey
}