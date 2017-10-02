# IDIA Execution Framework for DAG using Terraform

# Import your SSH public key into OpenStack and give it a name.
resource "openstack_compute_keypair_v2" "htc" {
  name = "htc-compute_keypair" # SSH key's name
  public_key = "${file("${var.ssh_key_file}.pub")}" # Path of your SSH key
}

# Create an Openstack router to route headnode and worker machines
# onto the internet.

resource "openstack_networking_router_v2" "htc" {
  name             = "htc"
  admin_state_up   = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_network_v2" "htc" {
  name           = "htc"
  admin_state_up = "true"
}

# Create a subnet which workers and headnode will communicate on.
resource "openstack_networking_subnet_v2" "htc" {
  name            = "htc"
  network_id      = "${openstack_networking_network_v2.htc.id}"
  cidr            = "10.0.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Create an interface on the network router.
resource "openstack_networking_router_interface_v2" "htc" {
  router_id = "${openstack_networking_router_v2.htc.id}"
  subnet_id = "${openstack_networking_subnet_v2.htc.id}"
}

# Create a resource for to retrieve a floating IP from the DHCP Pool
resource "openstack_networking_floatingip_v2" "htc" {
  pool       = "${var.pool}"
}

# We now associate the assigned floating ip to the instance created.
resource "openstack_compute_floatingip_associate_v2" "htc" {
  floating_ip = "${openstack_networking_floatingip_v2.htc.address}"
  instance_id = "${openstack_compute_instance_v2.htc.id}"
  depends_on = ["openstack_networking_router_interface_v2.htc"]
}

# Create the headnode instance so that users are able to login and submit jobs

resource "openstack_compute_instance_v2" "htc" {
  name = "htc"
  availability_zone = "uct"
  image_id = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.htc.name}"
  security_groups = ["default"]
  #floating_ip  = "${openstack_compute_floatingip_v2.htc.address}"
  network {
    name = "htc"
  }
}
