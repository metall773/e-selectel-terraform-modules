provider "openstack" {
  user_name           = var.os_user_name
  tenant_name         = var.os_project_name
  password            = var.os_user_password
  project_domain_name = var.os_domain_name
  user_domain_name    = var.os_domain_name
  auth_url            = var.os_auth_url
  region              = var.os_region
}

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

module "nat" {
  source = "../nat"
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

module "keypair" {
  source             = "../keypair"
  keypair_name       = "keypair-${random_string.random_name.result}"
  keypair_public_key = var.server_ssh_key
  keypair_user_id    = var.server_ssh_key_user
}

data "template_file" "init" {
  template = file("${path.module}/first-boot.sh")
  vars = {
    packages_4_install = "mc"
    install_autoupdate = "yes"
    install_fail2ban = "yes"
    firewall_udp_ports = ""
    firewall_tcp_ports = "22,443,80"
    install_bitrix  = "yes"
    install_bitrix_crm = "no"
    admin-username = "adm"
    mount_point = "fdf"
    share_name = "share"
    share_disk_name = "share_disk_name"
    storage_account = "storage_account"
    share_login = "share_login"
    share_disk_host = "share_disk_host"
    share_disk_login = "share_disk_login"
    share_disk_pass = "share_disk_pass"
    share_pass = "share_pass"
  }
}

output "cloud-init" {
  value = data.template_file.init.rendered
}

resource "openstack_compute_instance_v2" "instance_1" {
  name              = var.server_name
  image_id          = module.image_datasource.image_id
  flavor_id         = module.flavor.flavor_id
  key_pair          = module.keypair.keypair_name
  availability_zone = var.server_zone
  user_data         = data.template_file.init.rendered

  network {
    port = openstack_networking_port_v2.port_1.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

module "floatingip" {
  source = "../floatingip"
}

resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = openstack_networking_port_v2.port_1.id
  floating_ip = module.floatingip.floatingip_address
}
