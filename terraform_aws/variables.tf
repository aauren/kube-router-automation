######################### Variables definitions #########################
variable "aws_key_name" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name" {
  type    = string
  default = "kube-router"
}

variable "tags" {
  type = map(any)
  default = {
    owner = "kube-router"
  }
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/18"
}

variable "public_cidr_breakdowns" {
  type = map(any)
  default = {
    "a" = "10.0.0.0/24"
    "b" = "10.0.1.0/24"
    "c" = "10.0.2.0/24"
  }
}

variable "private_cidr_breakdowns" {
  type = map(any)
  default = {
    "a" = "10.0.3.0/24"
    "b" = "10.0.4.0/24"
    "c" = "10.0.5.0/24"
  }
}

variable "kube_worker_instance_size" {
  type    = string
  default = "t3.medium"
}

variable "bgp_receiver_instance_size" {
  type    = string
  default = "t3.micro"
}

variable "kube_worker_disk_size" {
  type    = number
  default = 50
}

variable "bgp_receiver_disk_size" {
  type    = number
  default = 10
}

variable "ami_filter" {
  type = list(any)
  default = [{
    name  = "name"
    value = "ubuntu-minimal/images/hvm-ssd/ubuntu-jammy-*-amd64-minimal-*"
  }]
}
