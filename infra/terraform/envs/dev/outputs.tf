output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.db.db_instance_endpoint
}

output "rds_db_name" {
  description = "Database name"
  value       = var.db_name
}

output "rds_master_username" {
  description = "RDS master username"
  value       = var.db_username
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN storing the RDS master user password"
  value       = module.db.master_user_secret_arn
}