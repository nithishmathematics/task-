# Terraform - dev environment (AWS VPC + EKS + RDS)

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Backend configuration example (uncomment and configure):
# terraform {
#   backend "s3" {
#     bucket         = "<your-terraform-state-bucket>"
#     key            = "task/dev/terraform.tfstate"
#     region         = "<region>"
#     dynamodb_table = "<lock-table>"
#     encrypt        = true
#   }
# }

locals {
  name       = "task-dev"
  cluster    = "task-dev-eks"
  cidr_block = "10.10.0.0/16"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = local.name
  cidr = local.cidr_block

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.10.0.0/20", "10.10.16.0/20"]
  private_subnets = ["10.10.32.0/20", "10.10.48.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = local.cluster
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      desired_size  = 2
      max_size      = 5
      min_size      = 2
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
}

# Security group for RDS allowing access from EKS nodes
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "RDS security group allowing EKS node access"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_ingress_pg" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.eks.node_security_group_id
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.5.0"

  identifier = "${local.name}-pg"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.db_username
  manage_master_user_password = true
  port                 = 5432

  multi_az             = false
  publicly_accessible  = false
  storage_encrypted    = true

  subnet_ids               = module.vpc.private_subnets
  vpc_security_group_ids   = [aws_security_group.rds.id]
  create_db_subnet_group   = true
  create_db_parameter_group = false

  skip_final_snapshot = true
}
