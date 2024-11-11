provider "aws" {
  region = var.region
}

provider "kubernetes" {
  alias = "eks"
  config_path = "~/.kube/config"
}


# __     ______   ____ 
# \ \   / /  _ \ / ___|
#  \ \ / /| |_) | |    
#   \ V / |  __/| |___ 
#    \_/  |_|    \____|
                     

## VPC-Module needs input to get the vpc created.

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.100.0.0/16"
  environment = "PROD"
  public_subnet_cidr = ["10.100.1.0/24","10.100.2.0/24","10.100.3.0/24"]
  private_subnet_cidr = ["10.100.6.0/24","10.100.7.0/24","10.100.8.0/24"]
  subnet_avaibility_zone = ["ap-south-1a","ap-south-1b","ap-south-1c"]
  nat_gateway = 2
  /* You need to make sure that subnet_avaibility_zone >= nat_gateway */
}

### Output related to the VPC Module
output "VPC-ID" {
  value = module.vpc.vpc_id
}
output "VPC-Private-Subnet-IDs" {
  value = module.vpc.private_subnet_ids
}
output "VPC-Public-Subnet-IDs" {
  value = module.vpc.public_subnet_ids
}

###

#  _____ _  ______  
# | ____| |/ / ___| 
# |  _| | ' /\___ \ 
# | |___| . \ ___) |
# |_____|_|\_\____/ 

#eks module requirement needs the subnet-id, which we can fetch from the above vpc module and the cluster name
#which we are getting from the tfvars file   

module "eks" {
  source = "./modules/eks"
  subnet_id = module.vpc.private_subnet_ids
  cluster_name = var.cluster_name
  depends_on = [ module.vpc ]
}

## Need the kubeconfig to be get downloaded to the local.

resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.eks-cluster.id}"
    }
    depends_on = [ module.eks ]
}

locals {
  eks_endpoint = replace(module.eks.eks-cluster.endpoint, "https://", "")
}

resource "null_resource" "dns_check" {
  count = 5
  provisioner "local-exec" {
    command = <<EOT
      if nslookup ${local.eks_endpoint}; then
        exit 0
      else
        echo "Retrying DNS check..." && sleep 10 && exit 1
      fi
    EOT
  }
  depends_on = [module.eks, null_resource.kubectl]
}


#  ____   ___   ____ _  _______ ____       ____  _   _ ____  _   _ 
# |  _ \ / _ \ / ___| |/ / ____|  _ \     |  _ \| | | / ___|| | | |
# | | | | | | | |   | ' /|  _| | |_) |____| |_) | | | \___ \| |_| |
# | |_| | |_| | |___| . \| |___|  _ <_____|  __/| |_| |___) |  _  |
# |____/ \___/ \____|_|\_\_____|_| \_\    |_|    \___/|____/|_| |_|
                                                                 
### Now we need to create a sample docker image, creatng it and pushing it to the dockerhub, we need to provide the 
### image name variable as per the docker push standard and then the username and password of the dockerhub

module "Docker-Push" {
  source = "./modules/Docker-Push"
  image_name = var.docker_image_name
  docker_username = var.docker_username
  docker_password = var.docker_password
}

#  ____  _____ ____  _     _____   ____  __ _____ _   _ _____ 
# |  _ \| ____|  _ \| |   / _ \ \ / /  \/  | ____| \ | |_   _|
# | | | |  _| | |_) | |  | | | \ V /| |\/| |  _| |  \| | | |  
# | |_| | |___|  __/| |__| |_| || | | |  | | |___| |\  | | |  
# |____/|_____|_|   |_____\___/ |_| |_|  |_|_____|_| \_| |_|  
# 

## Now we need the above image to be get deployed to the newly created eks cluster
module "Deployment-to-EKS" {
  source = "./modules/Deployment-to-EKS"
  namespace = "exercise"
  app_name = "nginx" 
  app_image = var.docker_image_name
  kubernetes_context_name = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.cluster_name}"
  providers = {
    kubernetes = kubernetes.eks
  }
  depends_on = [ module.Docker-Push, null_resource.dns_check ]
}

## as we are exposing the service in the deployment, we need to the endpoint to view the deployed image output.

output "Service-Endpoint" {
  value = module.Deployment-to-EKS.Service-Endpoint.status.0.load_balancer.0.ingress.0.hostname
}