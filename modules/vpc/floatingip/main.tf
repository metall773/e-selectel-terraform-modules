resource "openstack_networking_floatingip_v2" "floatingip_1" {
  pool = "external-network"
}

resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = var.port_id
  floating_ip = openstack_networking_floatingip_v2.floatingip_1.address
}