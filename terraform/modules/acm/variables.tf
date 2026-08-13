variable "project_name" {
  type = string  
}

variable "environment" {
  type = string  
}

variable "domain_name" {
  type = string  
}

variable "subject_alternative_names" {
  type = list(string)

  default = []  
}

variable "hosted_zone_id" {
  type = string  
}