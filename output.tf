#Outputs file
output "ip-public" {
  description = "Get the public IP of the VM"
  value = azurerm_public_ip.azure-web-ip.ip_address
}