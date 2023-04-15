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