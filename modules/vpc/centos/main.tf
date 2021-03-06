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
    vm_firewall_sshd_net  = var.vm_firewall_sshd_net
  }
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

resource "selectel_domains_record_v1" "a_record_local" {
  domain_id = var.vm_dns_domain_id
  name      = "local.${var.server_name}.${var.vm_dns_domain_name}"
  type      = "A"
  content   = openstack_compute_instance_v2.instance_1.access_ip_v4
  ttl       = 60
}

module "floatingip" {
  count = var.enable_floatingip ? 1 : 0

  source             = "../floatingip"
  port_id            = openstack_networking_port_v2.port_1.id
  vm_dns_domain_id   = var.vm_dns_domain_id
  vm_dns_domain_name = var.vm_dns_domain_name
  server_name        = var.server_name
}
