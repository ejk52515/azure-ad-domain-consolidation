locals {
  common_tags = {
    Environment = "Lab"
    Project     = "AD-Domain-Consolidation-Hybrid-Entra"
    Owner       = "Elijah-Korkoyah"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-ad-consolidation"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "target" {
  name                 = "snet-target"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "source" {
  name                 = "snet-source"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.20.30.0/24"]
}
resource "azurerm_network_security_group" "domain" {
  name                = "nsg-domain-private"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-RDP-From-Management"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.20.30.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-RDP-From-Other-VNet-Hosts"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "management" {
  name                = "nsg-management"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-RDP-From-Home"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.my_ip_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "target" {
  subnet_id                 = azurerm_subnet.target.id
  network_security_group_id = azurerm_network_security_group.domain.id
}

resource "azurerm_subnet_network_security_group_association" "source" {
  subnet_id                 = azurerm_subnet.source.id
  network_security_group_id = azurerm_network_security_group.domain.id
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_public_ip" "migsync" {
  name                = "pip-migsync01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "target_dc" {
  name                = "nic-tgt-dc01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.target.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.10.4"
  }
}

resource "azurerm_network_interface" "source_dc" {
  name                = "nic-src-dc01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.source.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.20.4"
  }
}

resource "azurerm_network_interface" "migsync" {
  name                = "nic-migsync01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.30.10"
    public_ip_address_id          = azurerm_public_ip.migsync.id
  }
}
resource "azurerm_windows_virtual_machine" "target_dc" {
  name                 = "TGT-DC01"
  computer_name        = "TGT-DC01"
  location             = azurerm_resource_group.lab.location
  resource_group_name  = azurerm_resource_group.lab.name
  size                 = var.target_dc_size
  disk_controller_type = "NVMe"
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.target_dc.id
  ]

  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    name                 = "osdisk-tgt-dc01"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}

  tags = local.common_tags
}
resource "azurerm_windows_virtual_machine" "source_dc" {
  name                 = "SRC-DC01"
  computer_name        = "SRC-DC01"
  location             = azurerm_resource_group.lab.location
  resource_group_name  = azurerm_resource_group.lab.name
  size                 = var.source_dc_size
  disk_controller_type = "NVMe"
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.source_dc.id
  ]

  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    name                 = "osdisk-src-dc01"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}

  tags = local.common_tags
}
resource "azurerm_windows_virtual_machine" "migsync" {
  name                 = "MIGSYNC01"
  computer_name        = "MIGSYNC01"
  location             = azurerm_resource_group.lab.location
  resource_group_name  = azurerm_resource_group.lab.name
  size                 = var.migsync_size
  disk_controller_type = "NVMe"
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.migsync.id
  ]

  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    name                 = "osdisk-migsync01"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}

  tags = local.common_tags
}
resource "azurerm_dev_test_global_vm_shutdown_schedule" "target_dc" {
  virtual_machine_id = azurerm_windows_virtual_machine.target_dc.id
  location           = azurerm_resource_group.lab.location
  enabled            = true

  daily_recurrence_time = var.shutdown_time
  timezone              = "Central Standard Time"

  notification_settings {
    enabled = false
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "source_dc" {
  virtual_machine_id = azurerm_windows_virtual_machine.source_dc.id
  location           = azurerm_resource_group.lab.location
  enabled            = true

  daily_recurrence_time = var.shutdown_time
  timezone              = "Central Standard Time"

  notification_settings {
    enabled = false
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "migsync" {
  virtual_machine_id = azurerm_windows_virtual_machine.migsync.id
  location           = azurerm_resource_group.lab.location
  enabled            = true

  daily_recurrence_time = var.shutdown_time
  timezone              = "Central Standard Time"

  notification_settings {
    enabled = false
  }
}