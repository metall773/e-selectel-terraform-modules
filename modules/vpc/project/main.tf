resource "selectel_vpc_project_v2" "project_1" {
  name        = var.project_name
  auto_quotas = true

    quotas {
    resource_name = "compute_cores"
    resource_quotas {
      region = var.os_region
      zone = var.server_zone
      value = var.compute_cores_quotas
    }
  }

  quotas {
    resource_name = "compute_ram"
    resource_quotas {
      region = var.os_region
      zone = var.server_zone
      value = var.compute_ram_quotas
    }
  }

  quotas {
    resource_name = "volume_gigabytes_basic"
    resource_quotas {
      region = var.os_region
      zone = var.server_zone
      value = var.volume_gigabytes_basic_quotas
    }
  }

  quotas {
    resource_name = "volume_gigabytes_fast"
    resource_quotas {
      region = var.os_region
      zone = var.server_zone
      value = var.volume_gigabytes_fast_quotas
    }
  }

  quotas {
    resource_name = "volume_gigabytes_local"
    resource_quotas {
      region = var.os_region
      zone = var.server_zone
      value = var.volume_gigabytes_local_quotas
    }
  }

}
