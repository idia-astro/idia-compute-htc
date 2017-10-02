# IDIA Execution Framework for DAG using Terraform

# Import your SSH public key into OpenStack and give it a name.
resource "openstack_compute_keypair_v2" "htc" {
  name = "htc-compute_keypair" # SSH key's name
  public_key = "${file("${var.ssh_key_file}.pub")}" # Path of your SSH key
}

resource "openstack_networking_network_v2" "htc" {
  name           = "htc"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "htc" {
  name            = "htc"
  network_id      = "${openstack_networking_network_v2.htc.id}"
  cidr            = "10.0.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "htc" {
  name             = "htc"
  admin_state_up   = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_router_interface_v2" "htc" {
  router_id = "${openstack_networking_router_v2.htc.id}"
  subnet_id = "${openstack_networking_subnet_v2.htc.id}"
}

resource "openstack_compute_floatingip_v2" "htc" {
  pool       = "${var.pool}"
  depends_on = ["openstack_networking_router_interface_v2.htc"]
}

resource "openstack_compute_instance_v2" "htc" {
  name = "htc"
  image_id = "${var.image}"
  flavor_id = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.htc.name}"
  security_groups = ["${openstack_compute_secgroup_v2.htc.name}"]
  floating_ip = "${openstack_compute_floatingip_v2.htc.address}"

  network {
    uuid = "${openstack_networking_network_v2.htc.id}"
  }
}
