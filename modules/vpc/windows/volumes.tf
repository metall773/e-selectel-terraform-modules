module "image_datasource" {
  source     = "../image_datasource"
  image_name = var.server_image_name
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each          = var.data_volumes
  name              = "${each.key}-for-${var.server_name}"
  size              = each.value.size_gb
  volume_type       = each.value.volume_type
  availability_zone = var.server_zone
}