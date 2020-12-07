module "project" {
  source       = "../project"
  project_name = var.project_name
  os_region                    = var.os_region
  server_zone                  = var.server_zone
  compute_cores_quotas         = var.compute_cores_quotas
  compute_ram_quotas           = var.compute_ram_quotas
  volume_gigabytes_fast_quotas = var.volume_gigabytes_fast_quotas  
}

module "user" {
  source        = "../user"
  user_name     = var.user_name
  user_password = var.user_password
}

module "role" {
  source          = "../role"
  role_project_id = module.project.project_id
  role_user_id    = module.user.user_id
}
