variable "os_user_name" {}

variable "os_project_name" {}

variable "os_user_password" {}

variable "os_domain_name" {}

variable "os_auth_url" {}

variable "os_region" {}

variable "server_vcpus" {
  default = 4
}

variable "server_ram_mb" {
  default = 8192
}

variable "server_root_disk_gb" {
  default = 8
}

variable "server_name" {
  default = "server_1"
}

variable "server_image_name" {}

variable "server_zone" {
  default = "ru-3a"
}

variable "server_ssh_key" {}

variable "server_ssh_key_user" {}

variable "vm_packages_4_install" {}
variable "vm_install_autoupdate" {}
variable "vm_install_fail2ban"   {}
variable "vm_firewall_udp_ports" {}
variable "vm_firewall_tcp_ports" {}
variable "vm_install_bitrix"     {}
variable "vm_install_bitrix_crm" {}
variable "vm_admin-username"     {}

variable "network_id" {}
variable "subnet_id" {}