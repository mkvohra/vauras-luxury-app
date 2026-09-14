aws_region = "ap-south-1"

project_name = "vauras-luxury-app"

environment = "dev"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "ap-south-1a",
  "ap-south-1b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

repositories = [
  "auth-service",
  "cart-service"
]

app_namespaces = [
  "auth",
  "cart"
]

cluster_version = "1.33"

node_instance_types = [
  "t3.medium"
]

desired_size = 2

min_size = 2

max_size = 4

bucket_name = "vauras"

domain_name = "vauras.xyz"

enable_versioning = true

#RDS

db_name = "luxe_db_dev"

db_username = "luxe_admin_dev"

db_instance_class = "db.t3.micro"

allocated_storage = 20

engine_version = "16.4"

multi_az = false

deletion_protection = false

skip_final_snapshot = true 

#IAM/GITHUB OIDC

github_org = "mkvohra"

github_repo = "vauras-luxury-app"

terraform_state_bucket = "vauras-terraform-state"

terraform_lock_table = "vauras-terraform-locks"

frontend_subdomain = "app-dev"

api_subdomain = "api-dev"