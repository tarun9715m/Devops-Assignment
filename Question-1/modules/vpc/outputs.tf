output "vpc_id" {
  value = aws_vpc.my-vpc.id
}

output "private_subnet_ids" {
  value = [
    for subnet in aws_subnet.private-subnets : subnet.id
  ]
}

output "public_subnet_ids" {
  value = [
    for subnet in aws_subnet.public-subnets : subnet.id
  ]
}