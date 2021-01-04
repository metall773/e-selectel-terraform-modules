#resource "selectel_domains_record_v1" "a_record_local" {
#  domain_id = var.vm_dns_domain_id
#  name      = "local.${var.server_name}.${var.vm_dns_domain_name}"
#  type      = "A"
#  content   = openstack_compute_instance_v2.instance_1.network[1].fixed_ip_v4
#  ttl       = 60
#}
