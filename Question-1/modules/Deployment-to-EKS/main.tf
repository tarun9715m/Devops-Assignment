terraform {
  required_providers {
    kubernetes = {}
  }
}


resource "kubernetes_namespace" "exercise" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment_v1" "nginx-deployment" {
  metadata {
    namespace = kubernetes_namespace.exercise.id
    name = var.app_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          image = var.app_image
          name  = var.app_name
        }
      }
    }
  }
}


resource "kubernetes_service" "example" {
  metadata {
    name = "${var.app_name}-svc"
    namespace = kubernetes_namespace.exercise.id
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type": "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type": "instance"
    }
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}