#Define application name
variable "prefix" {
  type = string
  description = "Prefix"
  default = "remis"
}
variable "app_name" {
  type = string
  description = "Application name"
  default = "web"
}
#Define application environment
variable "app_environment" {
  type = string
  description = "Application environment"
  default = "demo"
}
#Location Resource Group
variable "rg_location" {
  type = string
  description = "Location of Resource Group where to deploy"
}
variable "loc" {
  type = string
  description = "Naming for the location"
}
#VNET CIDR
variable "azure_vnet_cidr" {
  type = string
  description = "Vnet CIDR"
  default = "10.2.0.0/16"
}
#Subnet CIDR
variable "azure_subnet_cidr" {
  type = string
  description = "Subnet CIDR"
  default = "10.2.1.0/24"
}
#Instance Type
variable "instance_type" {
  type = string
  description = "Instance type to deploy"
}
