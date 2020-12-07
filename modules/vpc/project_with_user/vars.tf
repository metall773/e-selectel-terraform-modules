variable "project_name" {
  default = "tf_project"
}

variable "user_name" {
  default = "tf_user"
}

variable "user_password" {}

variable "os_region" {
  default = "ru-7"
}

variable "server_zone" {
  default = "ru-7a"
}

variable "compute_cores_quotas" {
  description = "CPU cores quota for the project"
  default = "16"
}

variable "compute_ram_quotas" {
  description = "RAM memory quota in Mb for the project"
  default = "24576"
}

variable "volume_gigabytes_basic_quotas" {
  description = "Basic Disk quota in Gb for the project"
  default     = "250"
}

variable "volume_gigabytes_fast_quotas" {
  description = "Disk quota in Gb for the project"
  default = "200"
}

variable "volume_gigabytes_local_quotas" {
  description = "Local Disk quota in Gb for the project"
  default = "200"
}