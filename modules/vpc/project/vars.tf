variable "project_name" {
  default = "project_1"
}

variable "os_region" {
  default = "ru-7"
}

variable "server_zone" {
  default = "ru-7a"
}

variable "quotas" {
  type = map(any)
}