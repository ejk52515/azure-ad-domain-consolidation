variable "subscription_id" {
  type        = string
  description = "Azure subscription used for the lab."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region where the lab resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-ad-consolidation"
  description = "Resource group containing the domain consolidation lab."
}
variable "admin_username" {
  type        = string
  default     = "azureadmin"
  description = "Local administrator username created on all three Windows VMs."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Unique local administrator password for the three Windows VMs."

  validation {
    condition     = length(var.admin_password) >= 14
    error_message = "The administrator password must contain at least 14 characters."
  }
}
variable "my_ip_cidr" {
  type        = string
  description = "Current public IPv4 address in /32 CIDR format for restricted RDP access."

  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0))
    error_message = "my_ip_cidr must be a valid CIDR value, such as 203.0.113.10/32."
  }
}
variable "target_dc_size" {
  type        = string
  default     = "Standard_F1ams_v7"
  description = "VM size for the corp.lab target domain controller."
}

variable "source_dc_size" {
  type        = string
  default     = "Standard_F1ams_v7"
  description = "VM size for the acquired.lab source domain controller."
}

variable "migsync_size" {
  type        = string
  default     = "Standard_F2ams_v7"
  description = "VM size for the migration, management, and Entra synchronization server."
}
variable "shutdown_time" {
  type        = string
  default     = "2300"
  description = "Daily Azure auto-shutdown time in HHmm format."

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.shutdown_time))
    error_message = "shutdown_time must use 24-hour HHmm format, such as 2300."
  }
}
