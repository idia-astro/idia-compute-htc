variable "image" {
  default = "Ubuntu 16.04"
}

variable "flavor" {
  default = "m1.medium"
}

variable "ssh_key_file" {}

variable "ssh_user_name" {
  default = "ubuntu"
}

variable "external_gateway" {}

variable "pool" {
  default = "public"
}
