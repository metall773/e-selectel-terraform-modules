output "server_id" {
  value = openstack_compute_instance_v2.instance_1.id
}

output "server_port_id" {
  value = openstack_networking_port_v2.port_1.id
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

output "bitrix" {
  value = var.vm_install_bitrix
}

output "bitrix_crm" {
  value = var.vm_install_bitrix_crm
}

output "cloud-init" {
  value = data.template_file.init.rendered
}