variable "image" {
  default = "ubuntu 16.04 LTS amd64"
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
