terraform {
  # backend "remote" {
  #   organization = var.organization
  #   workspaces = {
  #     name = var.cluster_workspace
  #   }
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.3"
    }
  }

  required_version = "~> 0.14"
}

data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "../learn-terraform-pipelines-k8s/terraform.tfstate"
  }
}

data "terraform_remote_state" "consul" {
  backend = "local"

  config = {
    path = "../learn-terraform-pipelines-consul/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.eks_cluster.outputs.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
