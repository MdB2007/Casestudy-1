# DB Subnet Group (voor private subnets)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "demo-rds-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]

  tags = { Name = "demo-rds-subnet-group" }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier             = "demo-postgres"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = { Name = "demo-postgres-db" }
}
