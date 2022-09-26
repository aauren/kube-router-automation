provider "aws" {
  region = var.region
}

locals {
  public_subnets = {
    for k, v in var.public_cidr_breakdowns :
    "${var.region}${k}" => v
  }
  private_subnets = {
    for k, v in var.private_cidr_breakdowns :
    "${var.region}${k}" => v
  }

  multiple_instances = {
    controller = {
      instance_type     = var.kube_worker_instance_size
      availability_zone = element(keys(local.private_subnets), 0)
      subnet_id         = element(aws_subnet.private.*.id, 0)
      root_block_device = {
        encrypted   = true
        volume_type = "gp2"
        volume_size = var.kube_worker_disk_size
        tags = {
          Name = "controller-root-block"
        }
      }
      tags = {
        type = "controller"
      }
    }
    worker = {
      instance_type     = var.kube_worker_instance_size
      availability_zone = element(keys(local.private_subnets), 1)
      subnet_id         = element(aws_subnet.private.*.id, 1)
      root_block_device = {
        encrypted   = true
        volume_type = "gp2"
        volume_size = var.kube_worker_disk_size
        tags = {
          Name = "worker-root-block"
        }
      }
      tags = {
        type = "worker"
      }
    }
    bgp = {
      instance_type     = var.bgp_receiver_instance_size
      availability_zone = element(keys(local.private_subnets), 2)
      subnet_id         = element(aws_subnet.private.*.id, 2)
      root_block_device = {
        encrypted   = true
        volume_type = "gp2"
        volume_size = var.bgp_receiver_disk_size
        tags = {
          Name = "bgp-root-block"
        }
      }
      tags = {
        type = "bgp"
      }
    }
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  dynamic "filter" {
    for_each = var.ami_filter
    content {
      name   = filter.value["name"]
      values = [filter.value["value"]]
    }
  }

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_security_group" "web-sg" {
  name   = "new-secgrp"
  vpc_id = aws_vpc.kube_router_main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_instance" "kube-controller" {
  depends_on = [aws_internet_gateway.gw]

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.multiple_instances.controller.instance_type
  key_name                    = var.aws_key_name
  availability_zone           = local.multiple_instances.controller.availability_zone
  subnet_id                   = local.multiple_instances.controller.subnet_id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/configs/cloud_init.cfg")

  root_block_device {
    encrypted   = local.multiple_instances.controller.root_block_device.encrypted
    volume_size = local.multiple_instances.controller.root_block_device.volume_size
    volume_type = local.multiple_instances.controller.root_block_device.volume_type
    tags        = local.multiple_instances.controller.root_block_device.tags
  }
  tags = merge(
    { "Name" = var.name },
    var.tags,
    local.multiple_instances.controller.tags
  )
}

resource "aws_instance" "kube-worker" {
  depends_on = [aws_internet_gateway.gw]

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.multiple_instances.worker.instance_type
  key_name                    = var.aws_key_name
  availability_zone           = local.multiple_instances.worker.availability_zone
  subnet_id                   = local.multiple_instances.worker.subnet_id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/configs/cloud_init.cfg")

  root_block_device {
    encrypted   = local.multiple_instances.worker.root_block_device.encrypted
    volume_size = local.multiple_instances.worker.root_block_device.volume_size
    volume_type = local.multiple_instances.worker.root_block_device.volume_type
    tags        = local.multiple_instances.worker.root_block_device.tags
  }
  tags = merge(
    { "Name" = var.name },
    var.tags,
    local.multiple_instances.worker.tags
  )
}

resource "aws_instance" "bgp-receiver" {
  depends_on = [aws_internet_gateway.gw]

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.multiple_instances.bgp.instance_type
  key_name                    = var.aws_key_name
  availability_zone           = local.multiple_instances.bgp.availability_zone
  subnet_id                   = local.multiple_instances.bgp.subnet_id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/configs/cloud_init.cfg")

  root_block_device {
    encrypted   = local.multiple_instances.bgp.root_block_device.encrypted
    volume_size = local.multiple_instances.bgp.root_block_device.volume_size
    volume_type = local.multiple_instances.bgp.root_block_device.volume_type
    tags        = local.multiple_instances.bgp.root_block_device.tags
  }
  tags = merge(
    { "Name" = var.name },
    var.tags,
    local.multiple_instances.bgp.tags
  )
}
