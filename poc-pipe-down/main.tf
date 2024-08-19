resource "aws_db_snapshot" "db_snapshot" {
  depends_on = [data.aws_db_instance.db_instance]

  db_instance_identifier = data.aws_db_instance.db_instance.db_instance_identifier
  db_snapshot_identifier = "dev-rds-instance-snapshot-dois"
}

data "aws_db_instance" "db_instance"{
    db_instance_identifier = "dev-rds-instance"
}

resource "null_resource" "execute_delete_script" {
  provisioner "local-exec" {
    command = "python3 delete-rds.py"
  }

  depends_on = [aws_db_snapshot.rds_snapshot]
}