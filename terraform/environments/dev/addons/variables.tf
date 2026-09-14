variable "project_name" {
  type = string  
}

variable "environment" {
  type = string  
}

variable "aws_region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "app_namespaces" {
  description = "Kubernetes namespaces that Terraform creates before application deployment"
  type        = list(string)
}
