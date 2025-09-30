# Terraform - dev environment (AWS + Azure)

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

# Backend configuration example (uncomment and configure):
# terraform {
#   backend "s3" {
#     bucket = "<your-terraform-state-bucket>"
#     key    = "task/dev/terraform.tfstate"
#     region = "<region>"
#     dynamodb_table = "<lock-table>"
#     encrypt = true
#   }
# }

# Modules (stubs, to be implemented)
# module "vpc" {
#   source = "../../modules/vpc"
#   name   = "task-dev"
#   cidr_block = "10.10.0.0/16"
# }
#
# module "eks" {
#   source        = "../../modules/eks"
#   cluster_name  = "task-dev-eks"
#   vpc_id        = module.vpc.id
#   private_subnet_ids = module.vpc.private_subnet_ids
# }
#
# module "aks" {
#   source       = "../../modules/aks"
#   cluster_name = "task-dev-aks"
#   location     = var.azure_location
# }
