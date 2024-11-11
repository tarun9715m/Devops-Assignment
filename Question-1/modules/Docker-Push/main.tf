terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = "registry-1.docker.io"
    username = var.docker_username
    password = var.docker_password
  }
}

resource "docker_image" "nginx-hello-world" {
  name = var.image_name
  build {
    context = "./modules/Docker-Push/"
  }
  platform = "linux/amd64"
}

resource "docker_registry_image" "helloworld" {
  name = docker_image.nginx-hello-world.name
}