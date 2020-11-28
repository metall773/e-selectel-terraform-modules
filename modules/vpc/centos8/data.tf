data "openstack_networking_floatingip_v2" "floating_ip" {
  name = module.floatingip.floatingip_address
}