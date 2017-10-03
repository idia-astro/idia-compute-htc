# Using the testing tenant associated with the ARC

variable "flavor" {
  default = "m1.medium"
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
