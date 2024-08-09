resource "random_password" "admin" {
  length  = 16
  special = true
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow-postgres"
  description = "Allow inbound PostgreSQL traffic"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir acesso de qualquer lugar
  }
}

data "aws_rds_engine_version" "pg_version" {
  engine  = "postgres"
  version = "12.15"
}

resource "aws_db_instance" "dbname" {
  allocated_storage         = 10
  identifier                = "db-instance-id"
  db_name                   = "dbname"
  engine                    = "postgres"
  engine_version            = data.aws_rds_engine_version.pg_version.version
  instance_class            = "db.t3.micro"
  username                  = "adminuser"
  password                  = random_password.admin.result
  skip_final_snapshot       = true  # Pulando o snapshot final na exclusão
  storage_encrypted         = true

  backup_retention_period = 5
  backup_window           = "07:00-09:00"

  maintenance_window = "Tue:05:00-Tue:07:00"

  vpc_security_group_ids = [
    aws_security_group.allow_postgres.id
  ]

  db_subnet_group_name = aws_db_subnet_group.default.name  # Referenciando o grupo de sub-rede criado

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      final_snapshot_identifier
    ]
  }
}

data "external" "rds_final_snapshot_exists" {
  program = [
    "${path.module}/check-rds-snapshot.sh",
    "db-instance-${terraform.workspace}"
  ]
}

data "aws_db_snapshot" "latest_snapshot" {
  count                  = data.external.rds_final_snapshot_exists.result.db_exists ? 1 : 0
  db_instance_identifier = "db-instance-id"
  most_recent            = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
  default     = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]  # Substitua pelos IDs reais das sub-redes
}

resource "aws_db_subnet_group" "default" {
  name       = var.subnet_db_name
  subnet_ids = var.subnet_ids
  description = "Subnet group for RDS DB instance"
}
