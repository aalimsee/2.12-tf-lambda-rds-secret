# Create an RDS instance
resource "aws_db_instance" "rds_instance" {
  identifier           = "mydbinstance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "db_user"
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # Add security group
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}