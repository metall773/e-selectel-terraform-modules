resource "selectel_vpc_project_v2" "project_1" {
  name        = var.project_name
  auto_quotas = true

  for_each = var.quotas
  quotas {
    resource_name = each.key
    resource_quotas {
      region = var.os_region
      zone   = var.server_zone
      value  = each.value
    }
  }
}