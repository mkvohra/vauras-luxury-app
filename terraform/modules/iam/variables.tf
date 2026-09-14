variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "terraform_state_bucket" {
  type = string
}

variable "terraform_lock_table" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "ecr_repositories" {
  type = list(string)
}

variable "app_namespaces" {
  description = "Kubernetes namespaces the deployment role is granted EKS access to (one per service, per the one-namespace-per-service decision)"
  type = list(string)
}