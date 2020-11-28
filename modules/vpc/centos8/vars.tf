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

variable "vm_packages_4_install" {
  default = ""
}
variable "vm_install_autoupdate" {
  default = "yes"
}
variable "vm_install_fail2ban" {
  description = "If set to yes, install fail2ban"
  default     = "yes"
}
variable "vm_firewall_udp_ports" {
  default = ""
}
variable "vm_firewall_tcp_ports" {
  default = "22"
}
variable "vm_install_bitrix" {
  default = "no"
}
variable "vm_install_bitrix_crm" {
  default = "no"
}
variable "vm_admin-username" {
  default = "tf-user"
}

variable "network_id" {}
variable "subnet_id" {}
variable "enable_floatingip" {
  description = "If set to true, enable floatingip"
  type        = bool
  default     = "false"
}

variable "vm_dns_domain_id" {
  description = "DNS domain id"
}

variable "vm_dns_domain_name" {
  description = "DNS domain"
}