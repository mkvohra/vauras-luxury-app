variable "project_name" {
  type = string  
}

variable "environment" {
  type = string  
}

variable "cluster_oidc_provider_arn" {
  type = string  
}

variable "cluster_oidc_issuer_url" {
  type = string  
}

variable "domain_name" {
  type = string
}

variable "app_secret_arn" {
  description = "ARN of the project's app-secrets in Secrets Manager, scoping ESO's IAM policy to just this one secret"
  type = string
}