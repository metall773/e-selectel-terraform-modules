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

resource "openstack_networking_port_v2" "port_1" {
  name       = "${var.server_name}-eth0"
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
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
    vm_packages_4_install = var.vm_packages_4_install
    vm_install_autoupdate = var.vm_install_autoupdate
    vm_install_fail2ban   = var.vm_install_fail2ban
    vm_firewall_udp_ports = var.vm_firewall_udp_ports
    vm_firewall_tcp_ports = var.vm_firewall_tcp_ports
    vm_install_bitrix     = var.vm_install_bitrix
    vm_install_bitrix_crm = var.vm_install_bitrix_crm
    vm_admin-username     = var.vm_admin-username
    #mount_point = ""
    #share_name = "share"
    #share_disk_name = "share_disk_name"
    #storage_account = "storage_account"
    #share_login = "share_login"
    #share_disk_host = "share_disk_host"
    #share_disk_login = "share_disk_login"
    #share_disk_pass = "share_disk_pass"
    #share_pass = "share_pass"
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
  count  = var.enable_floatingip ? 1 : 0
  source = "../floatingip"
}

resource "openstack_networking_floatingip_associate_v2" "association_1" {
  count  = var.enable_floatingip ? 1 : 0
  port_id     = openstack_networking_port_v2.port_1.id
  floating_ip = module.floatingip.floatingip_address
}