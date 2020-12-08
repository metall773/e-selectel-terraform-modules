locals {
  quotas_for_avaliability_zone = var.quotas["quotas_for_avaliability_zone"]
  quotas_for_region            = var.quotas["quotas_for_region"]
}

resource "selectel_vpc_project_v2" "project_1" {
  name        = var.project_name
  auto_quotas = true

  dynamic "quotas" {
    for_each = local.quotas_for_avaliability_zone
    content {
      resource_name = quotas.key
      resource_quotas {
        region = var.os_region
        zone   = var.server_zone
        value  = quotas.value
      }
    }
  }

  dynamic "quotas" {
    for_each = local.quotas_for_region
    content {
      resource_name = quotas.key
      resource_quotas {
        region = var.os_region
        value  = quotas.value
      }
    }
  }
}