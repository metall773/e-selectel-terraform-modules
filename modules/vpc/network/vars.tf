variable "os_user_name" {}

variable "os_project_name" {}

variable "os_user_password" {}

variable "os_domain_name" {}

variable "os_auth_url" {}

variable "os_region" {}

variable "router_external_net_name" {
  default = "external_network"
}

variable "router_name" {
  default = "router"
}

variable "network_name" {
  default = "network"
}

variable "subnet_cidr" {
  default = "192.168.70.0/24"
}