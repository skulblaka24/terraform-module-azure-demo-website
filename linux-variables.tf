#Linux VM Admin User
variable "linux_admin_user" {
  type = string
  description = "Linux VM Admin User"
  default = "tfadmin"
}
#Linux VM Admin Password
variable "linux_admin_password" {
  type = string
  description = "Linux VM Admin Password"
}
#Linux VM Hostname
variable "linux_vm_hostname" {
  type = string
  description = "Linux VM Hostname"
  default = "azwebserver1"
}
#Linux Publisher https://docs.microsoft.com/fr-fr/azure/virtual-machines/linux/cli-ps-findimage
variable "linux-publisher" {
  type = string
  description = "Linux Publisher"
  default = "OpenLogic"
}
#Linux Offer https://docs.microsoft.com/fr-fr/azure/virtual-machines/linux/cli-ps-findimage
variable "linux-offer" {
  type = string
  description = "Linux Offer"
  default = "CentOS"
}
#Linux SKU https://docs.microsoft.com/fr-fr/azure/virtual-machines/linux/cli-ps-findimage
variable "linux-sku" {
  type = string
  description = "Linux Server SKU"
  default = "7.5"
}