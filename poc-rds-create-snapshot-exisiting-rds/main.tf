resource "aws_db_snapshot" "db_snapshot" {
  depends_on = [data.aws_db_instance.db_instance]

  db_instance_identifier = data.aws_db_instance.db_instance.db_instance_identifier
  db_snapshot_identifier = "dev-rds-instance-snapshot-dois"
}

data "aws_db_instance" "db_instance"{
    db_instance_identifier = "dev-rds-instance-2"
}