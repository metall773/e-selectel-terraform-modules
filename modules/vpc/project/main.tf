resource "selectel_vpc_project_v2" "project_1" {
  name        = var.project_name
  auto_quotas = true

  dynamic "quotas" {
    for_each = var.quotas
    content {
      resource_name = quotas.key
      resource_quotas {
        region = var.os_region
        zone   = var.server_zone
        value  = quotas.value
      }
    }
  }
}