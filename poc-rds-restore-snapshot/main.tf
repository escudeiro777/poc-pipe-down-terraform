data "external" "rds_final_snapshot_exists" {
  program = [
    "./check-rds-snapshot.sh",
    "db-instance-${terraform.workspace}"
  ]
}

data "aws_db_snapshot" "latest_snapshot" {
  count                  = data.external.rds_final_snapshot_exists.result.db_exists ? 1 : 0
  db_instance_identifier = "db-instance-id"
  most_recent            = true
}

data "aws_rds_engine_version" "pg_version"{
  engine         = "postgres"
}

resource "random_password" "admin"{
  length = 16
  special = true
  override_special = "!#$%&*()"
}

resource "aws_security_group" "allow_postgres"{
  vpc_id = "vpc-0585299ce6b523bff"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  skip_final_snapshot       = false
  final_snapshot_identifier = "${terraform.workspace}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  snapshot_identifier       = try(data.aws_db_snapshot.latest_snapshot[0].id, null)
  storage_encrypted         = true

  backup_retention_period = 5
  backup_window           = "07:00-09:00"

  maintenance_window = "Tue:05:00-Tue:07:00"

  vpc_security_group_ids = [
    aws_security_group.allow_postgres.id
  ]

  db_subnet_group_name = var.subnet_db_name

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      final_snapshot_identifier
    ]
  }
}
