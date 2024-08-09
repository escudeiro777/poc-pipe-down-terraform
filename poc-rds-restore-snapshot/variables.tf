variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "subnet_db_name"{
  description = "teste"
}

variable "db_instance_identifier" {
  description = "O identificador da instância de banco de dados existente"
  type        = string
  default     = "existing-db-instance-id" # Substitua pelo identificador correto
}