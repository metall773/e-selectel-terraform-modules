variable "server_vcpus" {
  default = 4
}

variable "server_ram_mb" {
  default = 8192
}

variable "server_root_disk_gb" {
  default = 8
}

variable "server_second_disk_gb" {
  default = 5
}

variable "server_second_volume_type" {
  default = "fast.ru-3a"
}

variable "server_name" {
  description = "server name in selectel console"  
  default = "server_1"
}

variable "server_image_name" {
  description = "Predefined name from selectel image list"
  default = "Windows Server 2016 Standard"
}

#[root@jenkins e-selectel-terraform]# openstack image list
#+--------------------------------------+------------------------------------------+--------+
#| ID                                   | Name                                     | Status |
#+--------------------------------------+------------------------------------------+--------+
#| 2701c297-ecb1-4bfc-809a-c1a8af0c9c49 | CentOS 7 64-bit                          | active |
#| c8103478-ec5d-4e71-a54f-835baafa8d3c | CentOS 7 Minimal 64-bit                  | active |
#| e298df3f-b66d-46a5-9a66-b1b44a6d47a8 | CentOS 8 64-bit                          | active |
#| c5db3ece-9706-41a3-b6d0-cbef1eb63b61 | CoreOS                                   | active |
#| 31e44a4e-f6d3-4d45-8527-58cc02c41e5e | Debian 10 (Buster) 64-bit                | active |
#| ba971f57-636f-426b-ac83-a293bcbfd63e | Debian 9 (Stretch) 64-bit                | active |
#| aa20fe63-7f5d-4ecf-be25-fcb205585583 | Fedora 31 64-bit                         | active |
#| 27e217a5-c353-46f8-84fd-82a139e9c6c5 | Fedora 32 64-bit                         | active |
#| 71cc040e-d28a-40b7-afdf-abbcdd1948a7 | Fedora Atomic 29 64-bit                  | active |
#| 9b57af7f-9097-489c-b1fb-55a0ef46b887 | Ubuntu 16.04 LTS 64-bit                  | active |
#| 00675c5e-33ed-4365-96a8-a7900e0f1bb4 | Ubuntu 18.04 LTS 64-bit                  | active |
#| 2c29949a-ea10-4800-8008-30fb09de62e0 | Ubuntu 18.04 LTS Intel VTune 64-bit      | active |
#| 1225e21d-c053-4b5c-9f47-5d5c1f122b45 | Ubuntu 18.04 LTS Machine Learning 64-bit | active |
#| 4f67c8ce-20f4-49fe-95b5-6428738b06b4 | Ubuntu 18.04 MKS master stable           | active |
#| 65b402c5-c2de-4518-adbd-780b8981f601 | Ubuntu 18.04 MKS node stable             | active |
#| 6c756000-c7d9-4a61-b01e-da7f050aa820 | Ubuntu 20.04 LTS 64-bit                  | active |
#| 55383d29-12a1-4468-8748-2bedc9e0319a | Windows Server 2012 R2 Standard          | active |
#| c7ef53b4-6ae3-4e88-8f47-41b0cd2056c0 | Windows Server 2016 Standard             | active |
#| aa46c55d-0bdf-4562-afc3-49b2aae502c5 | Windows Server 2019 Standard Legacy BIOS | active |
#| 1720adde-1233-4cb1-bc2c-662bc1262bd8 | blank-simple-image                       | active |
#| c0896488-6f8c-4a07-b78b-f4ce81e38ecb | selectel-rescue-initrd                   | active |
#| 96aa7731-c1f6-4d59-91a1-bee0952935c0 | selectel-rescue-kernel                   | active |
#+--------------------------------------+------------------------------------------+--------+


variable "server_zone" {
  default = "ru-3a"
}

variable "admin_pass" {}

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
