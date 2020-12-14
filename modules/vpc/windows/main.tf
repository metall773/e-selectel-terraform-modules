resource "random_string" "random_name" {
  length  = 5
  special = false
}

module "flavor" {
  source               = "../flavor"
  flavor_name          = "flavor-${random_string.random_name.result}"
  flavor_vcpus         = var.server_vcpus
  flavor_ram_mb        = var.server_ram_mb
  flavor_local_disk_gb = var.server_root_disk_gb
}

resource "openstack_networking_port_v2" "port_1" {
  name       = "${var.server_name}-eth0"
  network_id = module.nat.network_id

  fixed_ip {
    subnet_id = module.nat.subnet_id
  }
}

module "image_datasource" {
  source     = "../image_datasource"
  image_name = var.server_image_name
}

resource "openstack_blockstorage_volume_v3" "volume_1" {
  name              = "volume-for-${var.server_name}"
  size              = var.server_second_disk_gb
  image_id          = module.image_datasource.image_id
  volume_type       = var.server_second_volume_type
  availability_zone = var.server_zone

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_instance_v2" "instance_1" {
  name              = var.server_name
  image_id          = module.image_datasource.image_id
  flavor_id         = module.flavor.flavor_id
  admin_pass        = var.admin_pass
  availability_zone = var.server_zone

  network {
    port = openstack_networking_port_v2.port_1.id
  }

  block_device {
    uuid             = module.image_datasource.image_id
    source_type      = "image"
    destination_type = "local"
    boot_index       = 0
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_1.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = -1
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

module "floatingip" {
  count = var.enable_floatingip ? 1 : 0

  source             = "../floatingip"
  port_id            = openstack_networking_port_v2.port_1.id
  vm_dns_domain_id   = var.vm_dns_domain_id
  vm_dns_domain_name = var.vm_dns_domain_name
  server_name        = var.server_name
}