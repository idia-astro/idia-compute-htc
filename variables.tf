# Using the testing tenant associated with the ARC

variable "flavor-head" {
  default = "idia.large"
}

variable "flavor-worker" {
  default = "idia.maximum"
}

variable "ssh_key_file" {
  default = "/home/tcarr/.ssh/terraform-htc"
}

variable "ssh_user_name" {
  default = "ubuntu"
}

variable "external_gateway" {
  default = "587e3171-708f-4a9c-9384-fbf44d27fa8a"
}

variable "pool" {
  default = "ext_net"
}

variable "public_cdir" {
  default = "137.158.0.0/16"
}

variable "private_cdir" {
  default = "10.0.0.0/24"
}

variable "ssh_port_num"{
  default = "22"
}

variable "clustername" {
  default = "IDIA"
}

variable "wait_time_vm" {
  default = "30"
}
