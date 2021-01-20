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

data "template_file" "init" {
  template = file("${path.module}/first-boot.ps1")
  vars = {
    install_packages = var.install_packages
  }
}

resource "openstack_compute_instance_v2" "instance_1" {
  depends_on = [selectel_vpc_license_v2.license_1]
  name              = var.server_name
  image_id          = module.image_datasource.image_id
  flavor_id         = module.flavor.flavor_id
  user_data         = data.template_file.init.rendered
  availability_zone = var.server_zone
  admin_pass        = var.admin_pass

  #network {
  #  port = openstack_networking_port_v2.port_1.id
  #}

  network {
    port = openstack_networking_port_v2.port_2.id
  }

  dynamic "network" {
    for_each = var.license_type != "" ? [var.license_type] : []

    content {
      name            = var.license_type
    }
  }

  block_device {
    uuid             = module.image_datasource.image_id
    source_type      = "image"
    destination_type = "local"
    boot_index       = 0
  }

  dynamic "block_device" {
    for_each = openstack_blockstorage_volume_v3.volumes
    content {
      uuid             = openstack_blockstorage_volume_v3.volumes[block_device.key].id
      source_type      = "volume"
      destination_type = "volume"
      boot_index       = -1
    }
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}
