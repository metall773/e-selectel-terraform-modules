module "image_datasource" {
  source     = "../image_datasource"
  image_name = var.server_image_name
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each             = var.data_volumes
  availability_zone    = var.server_zone
  description          = "Volume ${each.key} for server ${var.server_name}"
  name                 = "${var.server_name}_${each.key}"
  size                 = each.value.size_gb
  volume_type          = each.value.volume_type
  enable_online_resize = true
}