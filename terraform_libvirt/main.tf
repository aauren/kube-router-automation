######################### Providers #########################
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}


######################### General Definitions #########################
# Storage pool of where we will store our VM images
resource "libvirt_pool" "kube-router-storage" {
  name = "kube-router-storage"
  type = "dir"
  path = var.vm_pool_dir

  # We do this so that terraform doesn't repeatedly download the same image file which creates a lot of wasted time
  # and bandwidth. Also, this provider isn't capable of resizing the downloaded images, so the disks end up really
  # small. However, QEMU can expand the image to anything we want pretty easily.
  provisioner "local-exec" {
    command     = "${path.module}/../scripts/cache_ubuntu_img.sh"
    environment = {
      IMG_CACHE_DIR  = var.image_cache_dir
      UBUNTU_IMG_URL = var.ubuntu_image_url
      IMG_DISK_SIZE  = var.disk_size
    }
  }
}

# Setup the NAT network to use for our kube-router VMs
resource "libvirt_network" "kube-router-net" {
  name      = "kube-router-net"
  mode      = "nat"
  #domain    = "k8s.local"
  #addresses = ["10.241.0.0/16", "2001:db8:ca2:2::/64"]
  addresses = ["10.241.0.0/16"]
  dns {
    enabled = true
  }
}

# Template the user data found in configs/cloud_init.cfg
data "template_file" "user_data" {
  template = file("${path.module}/configs/cloud_init.cfg")
  vars = {
    root_password = var.root_password
    username = var.username
    user_ssh_key = var.user_ssh_key
    user_groups = var.user_groups
  }
}

# Template the network config found in configs/network.cfg
data "template_file" "network_config" {
  template = file("${path.module}/configs/network.cfg")
}

# Combine the two above templates and present it as a cloud-init ISO which is stored in the same pool as our images
# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.kube-router-storage.name
}


######################### Per kube-router VM Definitions #########################
resource "libvirt_volume" "kube-router-vm" {
  for_each = toset(["kube-router-vm1", "kube-router-vm2"])
  name   = each.key
  pool   = libvirt_pool.kube-router-storage.name
  source = "${var.image_cache_dir}/base_image.img"
  format = "qcow2"
}

resource "libvirt_domain" "kube-router-vm" {
  for_each = {
    kube-router-vm1 = "10.241.0.20"
    kube-router-vm2 = "10.241.0.21"
  }
  name   = each.key
  memory = var.memory_size
  vcpu   = var.cpu_count

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id     = libvirt_network.kube-router-net.id
    hostname       = each.key
    addresses      = [each.value]
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.kube-router-vm[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

######################### Per bgp-router VM Definitions #########################
resource "libvirt_volume" "bgp-router" {
  for_each = toset(["bgp-route-vm1"])
  name   = each.key
  pool   = libvirt_pool.kube-router-storage.name
  source = "${var.image_cache_dir}/base_image.img"
  format = "qcow2"
}

resource "libvirt_domain" "bgp-router-vm" {
  for_each = {
    bgp-route-vm1 = "10.241.0.10"
  }
  name   = each.key
  memory = var.bgp_memory_size
  vcpu   = var.bgp_cpu_count

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id     = libvirt_network.kube-router-net.id
    hostname       = each.key
    addresses      = [each.value]
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.bgp-router[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
