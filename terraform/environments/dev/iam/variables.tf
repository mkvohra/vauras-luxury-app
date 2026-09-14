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

variable "terraform_state_bucket" {
  type = string
}

variable "terraform_lock_table" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "repositories" {
  type = list(string)
}

variable "app_namespaces" {
  type = list(string)
}