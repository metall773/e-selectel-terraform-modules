output "server_id" {
  value = openstack_compute_instance_v2.instance_1.id
}

output "server_port_id" {
  value = openstack_networking_port_v2.port_1.id
}

output "floating_ip" {
  value = data.openstack_networking_floatingip_v2.floating_ip
}