data "openstack_networking_floatingip_v2" "floating_ip" {
  value = module.floatingip.floatingip_address
}