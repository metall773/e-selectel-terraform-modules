#resource "openstack_networking_port_v2" "port_1" {
#  name       = "${var.server_name}-eth1"
#  network_id = var.network_id
#
#  fixed_ip {
#    subnet_id = var.subnet_id
#  }
#}

resource "openstack_networking_port_v2" "port_2" {
  name       = "${var.server_name}-eth2"
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }
}

module "floatingip" {
  count = var.enable_floatingip ? 1 : 0

  source             = "../floatingip"
  port_id            = openstack_networking_port_v2.port_2.id
  vm_dns_domain_id   = var.vm_dns_domain_id
  vm_dns_domain_name = var.vm_dns_domain_name
  server_name        = var.server_name
}
