#GENERATE A RANDOM MASTER PASSWORD FOR THE DATABASE
#(Terraform creates this itself — never typed by a human, never stored in git)

resource "random_password" "db_password" {
  
  length = 20

  special = true

  #RDS doesn't allow these characters inside a password, so we exclude them
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

#-----------------------------------------------------------------------------------------

#SECURITY GROUP FOR RDS

resource "aws_security_group" "rds" {

  name = "${var.project_name}-${var.environment}-rds-sg" 

  description = "RDS Security Group"

  vpc_id = var.vpc_id

  tags = {
    Project = var.project_name
    Environment = var.environment
  } 
}

#-----------------------------------------------------------------------------------------

#SECURITY GROUP RULE (allowing postgres from eks)

resource "aws_security_group_rule" "postgres_from_eks" {

  type = "ingress"

  from_port = 5432
  to_port = 5432

  protocol = "tcp"

  security_group_id = aws_security_group.rds.id

  source_security_group_id = var.cluster_security_group_id   
}

#SECURITY GROUP OUTBOUND RULE

resource "aws_security_group_rule" "egress" {

  type = "egress"

  from_port = 0
  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.rds.id

}


#---------------------------------------------------------------------------------------
#DB SUBNET GROUP

resource "aws_db_subnet_group" "this" {

  name = "${var.project_name}-${var.environment}-db-subnet-group"

  subnet_ids = var.private_subnet_ids 

  tags = {
    Project = var.project_name
    Environment = var.environment
  } 
}

#--------------------------------------------------------------------------------

#POSTGRESQL RDS INSTANCE

resource "aws_db_instance" "this" {

  identifier = "${var.project_name}-${var.environment}"

  engine = "postgres"

  engine_version = var.engine_version

  instance_class = var.db_instance_class

  allocated_storage = var.allocated_storage

  storage_type = "gp3"

  db_name = var.db_name  

  username = var.db_username

  password = random_password.db_password.result

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  multi_az = var.multi_az

  publicly_accessible = false

  deletion_protection = var.deletion_protection

  skip_final_snapshot = var.skip_final_snapshot

  backup_retention_period = 7

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}