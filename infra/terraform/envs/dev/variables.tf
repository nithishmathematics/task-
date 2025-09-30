variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
  default     = "us-east-1"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "userdb"
}

variable "db_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "appuser"
}
