variable "environment" {
  type = string
  description = "Name of the Environment For e.g BETA,PROD,STAGING"
}


variable "vpc_cidr" {
    type = string
    description = "CIDR Range of the VPC"   
}

variable "private_subnet_cidr" {
    type = list
    description = "CIDR Range of the Private Subnet"
}

variable "public_subnet_cidr" {
    type = list
    description = "CIDR Range of the Public Subnet"
}

variable "subnet_avaibility_zone" {
    type = list
    description = "Subnet-AZ-Zone"  
}


variable "nat_gateway" {
    type = number
    description = "Number of Nat-Gateway"  
}


/* You need to make sure that subnet_avaibility_zone >= nat_gateway */