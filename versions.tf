terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    k3d = {
      source = "pvotal-tech/k3d"
      version = "0.0.6"
    }
  }
  required_version = ">= 1.3"
}