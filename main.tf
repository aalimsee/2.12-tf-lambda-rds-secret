
# Generate a random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name_prefix = "rds_credentials_"
  description = "Created by Aaron for RDS MySQL"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "db_user"
    password = random_password.db_password.result
    host     = aws_db_instance.rds_instance.endpoint
    dbname   = "mydatabase"
  })
}

# Enable automatic rotation for the secret
resource "aws_secretsmanager_secret_rotation" "rds_credentials_rotation" {
  secret_id           = aws_secretsmanager_secret.rds_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn

  rotation_rules {
    automatically_after_days = 30 # Rotate every 30 days
  }
}

# Create an RDS instance
/* resource "aws_db_instance" "rds_instance" {
  identifier           = "mydbinstance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydatabase"
  username             = "db_user"
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
} */

# Lambda function for secret rotation
/* resource "aws_lambda_function" "rotation_lambda" {
  function_name = "secret_rotation_lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.rotation_lambda_role.arn

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.rds_credentials.arn
    }
  }
} */

