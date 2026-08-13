variable "aws_region" {
  type = string  
}

variable "project_name" {
  type = string  
}

variable "environment" {
  type = string  
}

variable "cluster_version" {
  type = string
}

variable "node_instance_types" {
  type = list(string)
}

variable "desired_size" {
  type = number  
}

variable "min_size" {
  type = number  
}

variable "max_size" {
  type = number  
}

