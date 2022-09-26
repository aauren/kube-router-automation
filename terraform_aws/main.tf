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
    one = {
      instance_type     = var.kube_worker_instance_size
      availability_zone = element(keys(local.private_subnets), 0)
      subnet_id         = element(aws_subnet.private.*.id, 0)
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp2"
          volume_size = var.kube_worker_disk_size
          tags = {
            Name = "my-root-block"
          }
        }
      ]
    }
    two = {
      instance_type     = var.kube_worker_instance_size
      availability_zone = element(keys(local.private_subnets), 1)
      subnet_id         = element(aws_subnet.private.*.id, 1)
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp2"
          volume_size = var.kube_worker_disk_size
        }
      ]
    }
    three = {
      instance_type     = var.bgp_receiver_instance_size
      availability_zone = element(keys(local.private_subnets), 2)
      subnet_id         = element(aws_subnet.private.*.id, 2)
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp2"
          volume_size = var.bgp_receiver_disk_size
        }
      ]
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

module "ec2_multiple" {
  source     = "terraform-aws-modules/ec2-instance/aws"
  version    = "~> 3.0"
  depends_on = [aws_internet_gateway.gw]

  for_each = local.multiple_instances

  name = "${var.name}-multi-${each.key}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = each.value.instance_type
  key_name                    = var.aws_key_name
  availability_zone           = each.value.availability_zone
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  associate_public_ip_address = true

  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])

  tags = var.tags
}
