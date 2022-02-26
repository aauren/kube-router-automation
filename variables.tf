######################### Variables definitions #########################
variable "image_cache_dir" {
  type    = string
  default = "/tmp/kube-router-img-cache"
}

variable "ubuntu_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "vm_pool_dir" {
  type    = string
  default = "/var/lib/libvirt/kube-router-images"
}

variable "root_password" {
  type    = string
  default = "kube-router-linux"
}

variable "username" {
  type    = string
  default = "kube-router"
}

variable "user_ssh_key" {
  type    = string
  default = ""
}

variable "user_groups" {
  type    = string
  default = "adm"
}