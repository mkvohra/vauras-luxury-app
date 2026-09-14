terraform {

  required_version = ">= 1.5"

  required_providers {

    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"  
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    http = {
      source = "hashicorp/http"
    }
  }   
}





#GETTING CLUSTER DETAILS NEEDED FOR PROVIDER DETAILS

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name  
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name  
}


#ALL PROVIDERS

provider "aws" {
  region = var.aws_region
}



provider "kubernetes" {

  host = data.aws_eks_cluster.this.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.this.certificate_authority[0].data
  )

  token = data.aws_eks_cluster_auth.this.token
}


provider "helm" {
  kubernetes {

    host = data.aws_eks_cluster.this.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.this.certificate_authority[0].data
    )

    token = data.aws_eks_cluster_auth.this.token
  }
}