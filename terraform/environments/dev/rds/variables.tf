variable "project_name" {
  type = string  
}

variable "environment" {
  type = string  
}

variable "aws_region" {
  type = string  
}

variable "db_name" {
  type = string  
}

variable "db_username" {
  type = string  
}

variable "db_instance_class" {
  type = string  
}

variable "allocated_storage" {
  type = number  
}

variable "engine_version" {
  type = string  
}

variable "multi_az" {
  type = bool  
}

variable "deletion_protection" {
  type = bool  
}

variable "skip_final_snapshot" {
  type = bool  
}