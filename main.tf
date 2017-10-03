# IDIA Execution Framework for DAG using Terraform

# Find most recent Ubuntu 16.04 LTS Image
data "openstack_images_image_v2" "ubuntu1604" {
  name = "ubuntu 16.04 LTS amd64"
  most_recent = true
}

# Import your SSH public key into OpenStack and give it a name.
resource "openstack_compute_keypair_v2" "htc" {
  name = "htc-compute_keypair" # SSH key's name
  public_key = "${file("${var.ssh_key_file}.pub")}" # Path of your SSH key
}

# Create a network
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

# Create an Openstack Router to route traffic from the headnode and worker machines
resource "openstack_networking_router_v2" "htc" {
  name             = "htc"
  admin_state_up   = "true"
  external_gateway = "${var.external_gateway}"
}

# Create an interface on the network router.
resource "openstack_networking_router_interface_v2" "htc" {
  router_id = "${openstack_networking_router_v2.htc.id}"
  subnet_id = "${openstack_networking_subnet_v2.htc.id}"
}

# Create a resource to retrieve a floating IP from the DHCP Pool
resource "openstack_networking_floatingip_v2" "htc" {
  pool       = "${var.pool}"
}

# We now associate the assigned floating IP to the instance created.
resource "openstack_compute_floatingip_associate_v2" "htc" {
  floating_ip = "${openstack_networking_floatingip_v2.htc.address}"
  instance_id = "${openstack_compute_instance_v2.htc.id}"
  depends_on = ["openstack_networking_router_interface_v2.htc"]
}

// Create the headnode instance so that users are able to login and submit jobs.
// The depends_on module is needed so that the subnet is available before the instance
// is booted.

resource "openstack_compute_instance_v2" "htc" {
  name              = "htc-headnode"
  availability_zone = "uct"
  image_id          = "${data.openstack_images_image_v2.ubuntu1604.id}"
  flavor_name       = "${var.flavor}"
  key_pair          = "${openstack_compute_keypair_v2.htc.name}"
  security_groups    = ["default"]
  depends_on = ["openstack_networking_subnet_v2.htc"]
  network {
    name = "htc"
  }
    provisioner "remote-exec" {
      connection {
       agent       = "true"
       user        = "${var.ssh_user_name}"
       private_key = "${file(var.ssh_key_file)}"
     }
     inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y upgrade",
       ]
     }
}

# Create the worker nodes and increase / decrease the count based on the number workers required

resource "openstack_compute_instance_v2" "workers" {
  count = 2
  name = "${format("htc-worker-%02d", count.index+1)}"
  key_pair = "${openstack_compute_keypair_v2.htc.name}"
  availability_zone = "uct"
  image_id = "${data.openstack_images_image_v2.ubuntu1604.id}"
  flavor_name = "${var.flavor}"
  security_groups = ["default"]
  depends_on = ["openstack_compute_instance_v2.htc"]
  network {
    name = "htc"
  }
}

// The output is important so that Russ knows which headnode IP/DNS to connect to
// once the terraform completes. Complete this please....
output "ip" {
  value = "${openstack_networking_floatingip_v2.htc.address}"
}
