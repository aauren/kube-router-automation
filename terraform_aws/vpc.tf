resource "aws_vpc" "kube_router_main" {
  cidr_block = var.cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  assign_generated_ipv6_cidr_block = true

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.kube_router_main.id

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count      = length(local.public_subnets)
  cidr_block = element(values(local.public_subnets), count.index)
  vpc_id     = aws_vpc.kube_router_main.id

  map_public_ip_on_launch = true
  availability_zone       = element(keys(local.public_subnets), count.index)

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.kube_router_main.ipv6_cidr_block, 8, count.index)
  assign_ipv6_address_on_creation = true

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

#resource "aws_subnet" "private" {
#  count      = length(local.private_subnets)
#  cidr_block = element(values(local.private_subnets), count.index)
#  vpc_id     = aws_vpc.kube_router_main.id
#
#  map_public_ip_on_launch = true
#  availability_zone       = element(keys(local.private_subnets), count.index)
#
#  tags = merge(
#    { "Name" = var.name },
#    var.tags
#  )
#}

resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.kube_router_main.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_default_route_table.public.id
}

#resource "aws_route_table" "private" {
#  vpc_id = aws_vpc.kube_router_main.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.kube_router_nat_gw.id
#  }
#
#  tags = merge(
#    { "Name" = var.name },
#    var.tags
#  )
#}

#resource "aws_eip" "nat" {
#  vpc = true
#
#  tags = merge(
#    { "Name" = var.name },
#    var.tags
#  )
#}

#resource "aws_nat_gateway" "kube_router_nat_gw" {
#  allocation_id = aws_eip.nat.id
#  subnet_id     = aws_subnet.public.0.id
#
#  tags = merge(
#    { "Name" = var.name },
#    var.tags
#  )
#}
