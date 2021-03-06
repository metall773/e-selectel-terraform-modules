output "server_id" {
  value = openstack_compute_instance_v2.instance_1.id
}

output "server_port_id" {
  value = openstack_networking_port_v2.port_2.id
}

output "server_FQDN" {
  value = "${var.server_name}.${var.vm_dns_domain_name}"
}

output "server_FQDN_local" {
  value = "local.${var.server_name}.${var.vm_dns_domain_name}"
}

output "server_name" {
  value = var.server_name
}