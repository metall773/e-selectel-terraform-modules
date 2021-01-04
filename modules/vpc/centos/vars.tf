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
  description = "server name in selectel console"
  default     = "server_1"
}

variable "server_image_name" {
  description = "Predefined name from selectel image list"
  default     = "CentOS 8 64-bit"
}

variable "server_zone" {
  description = "Availability zone for server deploy"
  default     = "ru-3a"
}

variable "server_ssh_key" {}

variable "server_ssh_key_user" {}

variable "vm_packages_4_install" {
  description = "install centos packeges by bootstrap script"
  default     = ""
}
variable "vm_install_autoupdate" {
  description = "enable centos autoupdate by bootstrap script"
  default     = "yes"
}
variable "vm_install_fail2ban" {
  description = "If set to yes, install fail2ban"
  default     = "no"
}
variable "vm_firewall_udp_ports" {
  description = "List TCP ports to open on Firewalld by bootstrap script"
  default     = ""
}
variable "vm_firewall_tcp_ports" {
  description = "List TCP ports to open on Firewalld by bootstrap script"
  default     = "22"
}
variable "vm_install_bitrix" {
  description = "Deploy bitrix by bootstrap script"
  default     = "no"
}
variable "vm_install_bitrix_crm" {
  description = "Deploy bitrix CRM by bootstrap script"
  default     = "no"
}
variable "vm_admin-username" {
  description = "sudom, wheel user name"
  default     = "tf-user"
}

variable "network_id" {
  description = "Nework ID for VM"
}

variable "subnet_id" {
  description = "Subnet ID for VM"
}
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

variable "vm_firewall_sshd_net" {
  description = "Allow connect to sshd from listen network"
  default     = "any"
}