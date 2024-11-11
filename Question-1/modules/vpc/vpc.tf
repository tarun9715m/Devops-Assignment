locals {

    private_subnet_mapping = [

        for i in range(length(var.private_subnet_cidr)) : {
             cidr_block = var.private_subnet_cidr[i]
             availability_zone = var.subnet_avaibility_zone[i % length(var.subnet_avaibility_zone)]

        } 
    ]

    public_subnet_mapping = [

        for i in range(length(var.public_subnet_cidr)) : {
             cidr_block = var.public_subnet_cidr[i]
             availability_zone = var.subnet_avaibility_zone[i % length(var.subnet_avaibility_zone)]
        } 
    ]

    eip_allocation_id = [ for eip in aws_eip.eip: eip.allocation_id ]
    private_subnets = { for subnet_id, subnet_name in aws_subnet.private-subnets: subnet_id => subnet_name }
    public_subnets = { for subnet_id, subnet_name in aws_subnet.public-subnets: subnet_id => subnet_name }


    nat_gateway_mapping = [
        for i in range(length(local.eip_allocation_id)) : {
            allocation_id = local.eip_allocation_id[i % length(local.eip_allocation_id)]
            subnet_name = local.public_subnets[i].tags.Name
            subnet_id = local.public_subnets[i].id
            az_name = local.public_subnets[i].availability_zone
        }
    ]

    private_nateway_gw_ids = [ for ids in aws_nat_gateway.natgw: ids.id ]

    private_route_table_ids = [for ids in aws_route_table.private_route_table: ids.id]

    public_route_table_ids = [for ids in aws_route_table.public_route_table: ids.id]


    private_route_table_mapping = [
       for i in range(length(var.subnet_avaibility_zone)) : {
            nat_gateway_id = local.private_nateway_gw_ids[ i % length(local.eip_allocation_id)]
            subnet_name = local.private_subnets[i].tags.Name
            subnet_id = local.private_subnets[i].id
            az_name = local.private_subnets[i].availability_zone
       }

    ]


    private_route_table_association_mapping = [
       for i in range(length(var.private_subnet_cidr)) : {
            route_table_id = local.private_route_table_ids[i % length(var.subnet_avaibility_zone)]
            subnet_name = local.private_subnets[i].tags.Name
            subnet_id = local.private_subnets[i].id
       }
    ]

    public_route_table_association_mapping = [
       for i in range(length(var.public_subnet_cidr)) : {
            route_table_id = local.public_route_table_ids[i % length(var.subnet_avaibility_zone)]
            subnet_name = local.public_subnets[i].tags.Name
            subnet_id = local.public_subnets[i].id
       }

    ]
}

resource "aws_vpc" "my-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
      Name = "${var.environment}-VPC"
    }
}


resource "aws_subnet" "private-subnets" {
  for_each = { for index, subnet in local.private_subnet_mapping: index => subnet }
  vpc_id     = aws_vpc.my-vpc.id
  availability_zone = each.value.availability_zone
  cidr_block = each.value.cidr_block
  tags = {
    Name = "${var.environment}-VPC/PrivateSubnet-${each.key + 1}"
  }
}

resource "aws_subnet" "public-subnets" {
  for_each = { for index, subnet in local.public_subnet_mapping: index => subnet }
  vpc_id     = aws_vpc.my-vpc.id
  availability_zone = each.value.availability_zone
  cidr_block = each.value.cidr_block
  tags = {
    Name = "${var.environment}-VPC/PublicSubnet-${each.key + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "${var.environment}-VPC-IGW"
  }
}

resource "aws_eip" "eip" {
  count = var.nat_gateway
  tags = {
    Name = "EIP-${count.index}"
  }

}


resource "aws_nat_gateway" "natgw" {
  for_each = { for i in local.nat_gateway_mapping: i.az_name => i }
  subnet_id     = each.value.subnet_id
  allocation_id = each.value.allocation_id
  tags = {
    Name = "NAT-Gateway-${each.key}"
  }
  depends_on = [
     aws_internet_gateway.gw,
     aws_subnet.private-subnets,
     aws_subnet.public-subnets
     ]
}

resource "aws_route_table" "public_route_table" {
  for_each   = { for i in var.subnet_avaibility_zone: i => i}
  vpc_id     = aws_vpc.my-vpc.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-VPC/Public-RT-${each.key}"
  }

}

resource "aws_route_table" "private_route_table" {
  for_each   = { for i in local.private_route_table_mapping: i.subnet_name => i}
  vpc_id     = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = each.value.nat_gateway_id
  }

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = "${var.environment}-VPC/Private-RT-${each.value.az_name}"
  }

}


resource "aws_route_table_association" "public_route_table_association" {
  for_each =  { for i in local.public_route_table_association_mapping: i.subnet_name => i}
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}


resource "aws_route_table_association" "private_route_table_association" {
  for_each =  { for i in local.private_route_table_association_mapping: i.subnet_name => i}
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}


