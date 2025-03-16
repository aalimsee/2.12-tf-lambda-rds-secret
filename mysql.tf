

resource "aws_security_group" "rds_sg" {
  name   = "${local.name_prefix}-mysql"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# --- passwords must be at least 8 characters long and can't contain "/", "@", or double quotes ("")
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*-_=+[]{}<>:?"
}


resource "aws_db_instance" "mysql" {
  identifier        = "${local.name_prefix}-mysql-instance"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name = "mydb"

  # Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled
  //iam_database_authentication_enabled = true 

  # Set to true to allow RDS to manage the master user password in Secrets Manager
  # Secret created will be link to identifier?
  # rds!db-XXXX created
  manage_master_user_password = true
  username                    = "admin"

  //username = jsondecode(aws_secretsmanager_secret_version.mysql_secret_version.secret_string)["username"]
  //password = jsondecode(aws_secretsmanager_secret_version.mysql_secret_version.secret_string)["password"]

  publicly_accessible = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql_subnet_group.name

  apply_immediately = true
}

output "mysql_mydb_endpoint" { value = trim(aws_db_instance.mysql.endpoint, ":3306") }


# Access the secret ARN with manage_master_user_password = true
output "master_user_secret_arn" {
  value = aws_db_instance.mysql.master_user_secret[0].secret_arn
  //value = aws_db_instance.mysql.master_user_secret[0]
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name = "${local.name_prefix}-mysql-subnet-group"
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
}

/* data "aws_secretsmanager-secret" "mysql_secret" {
  arn = [aws_db_instance.mysql.master_user_secret[0].secret_name]
}

output "mysql_secret" {
  value = aws_secretsmanager_secret.mysql_secret.arn
} */

# --- below 3 resource blocks are remove since manage_master_user_password = true
/* # Create a Secrets Manager Secret for RDS MySQL.
resource "aws_secretsmanager_secret" "mysql_secret" {
  name                    = "${local.name_prefix}-mysql-secret-5"
  description             = "RDS MySQL Credentials"
  recovery_window_in_days = 7
}

# Attach the Lambda function to the Secrets Manager rotation process.
resource "aws_secretsmanager_secret_rotation" "mysql_rotation" {
  secret_id           = aws_secretsmanager_secret.mysql_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  //rotate_immediately  = true

  rotation_rules {
    //automatically_after_days = 30
    schedule_expression = "rate(4 hours)"
  }
}

resource "aws_secretsmanager_secret_version" "mysql_secret_version" {
  secret_id = aws_secretsmanager_secret.mysql_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.password.result

    //dbname   = "mydb"
    //engine   = "mysql"
    //dbname   = aws_db_instance.mysql.db_name
    //host     = aws_db_instance.mysql.address
    //port     = aws_db_instance.mysql.port
    //port     = 3306
    //dbInstanceIdentifier = "aaron-mysql-instance"
  })
} */



# Secrets Manager cannot invoke the specified Lambda function. Ensure that the function policy grants access to the principal secretsmanager.amazonaws.com.
resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  //source_arn = aws_secretsmanager_secret.mysql_secret.arn
  //source_arn = aws_db_instance.mysql.MasterUserSecret.SecretArn
  source_arn = "arn:aws:secretsmanager:us-east-1:255945442255:secret:*"
}

/*

# Create a Secrets Manager VPC Endpoint
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id           = "your-vpc-id" # Replace with your VPC ID
  subnet_ids       = ["subnet-xxxxxxxxxxxx", "subnet-yyyyyyyyyy"] # Replace with your subnet IDs
  service_name     = "com.amazonaws.region.secretsmanager" # Secrets Manager service name
  private_dns_only = true # Optional: For private DNS only
  tags = {
    Name = "secrets-manager-vpc-endpoint"
  }
}

*/



