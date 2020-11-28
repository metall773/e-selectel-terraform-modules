data "openstack_networking_floatingip_v2" "floating_ip" {
  address = module.floatingip.floatingip_address
}