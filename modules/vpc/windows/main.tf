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
  network_id = var.network_id
  fixed_ip {
    subnet_id = var.subnet_id
  }
}

resource "openstack_networking_port_v2" "port_2" {
  name       = "${var.server_name}-eth1"
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }
}

module "image_datasource" {
  source     = "../image_datasource"
  image_name = var.server_image_name
}

resource "openstack_blockstorage_volume_v3" "volume" {
  for_each          = var.data_volumes
  name              = "volume-for-${var.server_name}"
  size              = each.size_gb
  volume_type       = each.volume_type
  availability_zone = var.server_zone
}

data "template_file" "init" {
  template = file("${path.module}/first-boot.ps1")
  vars = {
    install_packages = var.install_packages
  }
}

resource "openstack_compute_instance_v2" "instance_1" {
  name              = var.server_name
  image_id          = module.image_datasource.image_id
  flavor_id         = module.flavor.flavor_id
  user_data         = data.template_file.init.rendered
  availability_zone = var.server_zone
  admin_pass        = var.admin_pass

  network {
    port = openstack_networking_port_v2.port_1.id
  }

  network {
    port = openstack_networking_port_v2.port_2.id
  }

  block_device {
    uuid             = module.image_datasource.image_id
    source_type      = "image"
    destination_type = "local"
    boot_index       = 0
  }

  block_device {
    for_each         = module.volume
    uuid             = each.volume.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = -1
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

resource "selectel_domains_record_v1" "a_record_local" {
  domain_id = var.vm_dns_domain_id
  name      = "local.${var.server_name}.${var.vm_dns_domain_name}"
  type      = "A"
  content   = openstack_compute_instance_v2.instance_1.network[1].fixed_ip_v4
  ttl       = 60
}

module "floatingip" {
  count = var.enable_floatingip ? 1 : 0

  source             = "../floatingip"
  port_id            = openstack_networking_port_v2.port_2.id
  vm_dns_domain_id   = var.vm_dns_domain_id
  vm_dns_domain_name = var.vm_dns_domain_name
  server_name        = var.server_name
}