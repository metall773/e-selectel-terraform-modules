resource "openstack_networking_floatingip_v2" "floatingip_1" {
  pool = "external-network"
}

resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = var.port_id
  floating_ip = openstack_networking_floatingip_v2.floatingip_1.address
}

resource "selectel_domains_record_v1" "a_record_bitrix01" {
  domain_id = var.vm_dns_domain_id
  name      = "${var.server_name}.${var.vm_dns_domain_name}"
  type      = "A"
  content   = openstack_networking_floatingip_v2.floatingip_1.address
  ttl       = 60
}