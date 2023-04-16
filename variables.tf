# Project name
variable "project-code" {
  description = "Project name should include the first letter of each surname of the team members."
  default     = "JTM"
}

# Location
variable "location" {
  description = "Azure region to deploy resources to."
  default     = "West Europe"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  default     = "adminuser"
}

variable "admin_ssh_pubkey" {
  description = "Admin SSH public key to use for the instances"
  default     = ""
}