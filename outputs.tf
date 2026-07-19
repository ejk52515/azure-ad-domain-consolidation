output "private_ip_addresses" {
  description = "Static private IP addresses assigned to the three lab servers."

  value = {
    "TGT-DC01"  = azurerm_network_interface.target_dc.ip_configuration[0].private_ip_address
    "SRC-DC01"  = azurerm_network_interface.source_dc.ip_configuration[0].private_ip_address
    "MIGSYNC01" = azurerm_network_interface.migsync.ip_configuration[0].private_ip_address
  }
}

output "vm_sizes" {
  description = "VM sizes selected for the quota-constrained lab."

  value = {
    "TGT-DC01"  = azurerm_windows_virtual_machine.target_dc.size
    "SRC-DC01"  = azurerm_windows_virtual_machine.source_dc.size
    "MIGSYNC01" = azurerm_windows_virtual_machine.migsync.size
  }
}