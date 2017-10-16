// Maintainer: Timothy Carr
// Terraform IAC for deploying an HTcondor cluster

// Find most recent Ubuntu 16.04 LTS Image
data "openstack_images_image_v2" "ubuntu1604" {
  name        = "idia-ubuntu-16.04-Ninja"
  most_recent = true
}

// Import your SSH public key into OpenStack and give it a name.
resource "openstack_compute_keypair_v2" "htc" {
  name        = "htc-compute_keypair" # SSH key's name
  public_key  = "${file("${var.ssh_key_file}.pub")}" # Path of your SSH key
}

// Create a network
resource "openstack_networking_network_v2" "htc" {
  name            = "htc"
  admin_state_up  = "true"
}

// Create a subnet which workers and headnode will communicate on.
resource "openstack_networking_subnet_v2" "htc" {
  name            = "htc"
  network_id      = "${openstack_networking_network_v2.htc.id}"
  cidr            = "192.168.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

// Create an Openstack Router to route traffic from the headnode and worker machines
resource "openstack_networking_router_v2" "htc" {
  name             = "htc"
  admin_state_up   = "true"
  external_gateway = "${var.external_gateway}"
}

// Create an interface on the network router.
resource "openstack_networking_router_interface_v2" "htc" {
  router_id     = "${openstack_networking_router_v2.htc.id}"
  subnet_id     = "${openstack_networking_subnet_v2.htc.id}"
}

// Create a resource to retrieve a floating IP from the DHCP Pool
resource "openstack_networking_floatingip_v2" "htc" {
  pool           = "${var.pool}"
}

// We now associate the assigned floating IP to the instance created.
resource "openstack_compute_floatingip_associate_v2" "htc" {
  floating_ip   = "${openstack_networking_floatingip_v2.htc.address}"
  instance_id   = "${openstack_compute_instance_v2.htc.id}"
  depends_on    = ["openstack_networking_router_interface_v2.htc"]
}

// Create the Security Groups
resource "openstack_compute_secgroup_v2" "secgroup_private_1" {
  name          = "htc-priv-sec-grp"
  description   = "htc-security group for private network"
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.private_cdir}"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_public_1" {
  name          = "htc-public-sec-grp"
  description   = "htc-security group for public network"
  rule {
    from_port   = "${var.ssh_port_num}"
    to_port     = "${var.ssh_port_num}"
    ip_protocol = "tcp"
    cidr        = "${var.public_cdir}"
  }
}

// Create a null resource for executing the provisioner process. If running this for the first time
// do not forget to run "terraform init" which will download the required resource module.
// Issue raised here - https://github.com/hashicorp/terraform/issues/13418
resource "null_resource" "provision" {
  depends_on = ["openstack_compute_floatingip_associate_v2.htc"]
  connection {
      host        = "${openstack_networking_floatingip_v2.htc.address}"
      user        = "${var.ssh_user_name}"
      private_key = "${file(var.ssh_key_file)}"
   }
  provisioner "remote-exec" {
   inline = [
    "sudo apt-get -y update",
    "sudo timedatectl set-timezone Africa/Johannesburg",
    "sudo apt-get install slurm-llnl",
     ]
    }
}

// Compute Instances
// Create the headnode instance so that users are able to login and submit jobs.
// The depends_on module is needed so that the subnet is available and attached before the instance
// is booted.
resource "openstack_compute_instance_v2" "htc" {
  name              = "htc-headnode"
  availability_zone = "uct"
  image_id          = "${data.openstack_images_image_v2.ubuntu1604.id}"
  flavor_name       = "${var.flavor-head}"
  key_pair          = "${openstack_compute_keypair_v2.htc.name}"
  security_groups   = ["${openstack_compute_secgroup_v2.secgroup_private_1.name}","${openstack_compute_secgroup_v2.secgroup_public_1.name}"]
  depends_on        = ["openstack_networking_subnet_v2.htc"]
  network {
    name = "htc"
  }
  network {
    name = "idia-bgfs"
  }
}

// Create the worker nodes and increase / decrease the count based on the number workers required
resource "openstack_compute_instance_v2" "workers" {
  count             = 1
  name              = "${format("htc-worker-%02d", count.index+1)}"
  key_pair          = "${openstack_compute_keypair_v2.htc.name}"
  availability_zone = "uct"
  image_id          = "${data.openstack_images_image_v2.ubuntu1604.id}"
  flavor_name       = "${var.flavor-worker}"
  security_groups   = ["${openstack_compute_secgroup_v2.secgroup_private_1.name}"]
  depends_on        = ["openstack_compute_instance_v2.htc"]
  network {
    name            = "htc"
  }
     provisioner "remote-exec" {
           inline = [
           "sudo apt-get -y update",
           "sudo timedatectl set-timezone Africa/Johannesburg",
           "sudo apt-get install slurm-llnl"

           ]
         connection {
            bastion_host                = "${openstack_networking_floatingip_v2.htc.address}"
            bastion_user                = "${var.ssh_user_name}"
            bastion_private_key         = "${file(var.ssh_key_file)}"
            user                        = "${var.ssh_user_name}"
            private_key                 = "${file(var.ssh_key_file)}"
          }
     }
}

// Output module allows can echo information about what has been completed.
output "headnode_ip" {
  value             = "${openstack_networking_floatingip_v2.htc.address}"
}
