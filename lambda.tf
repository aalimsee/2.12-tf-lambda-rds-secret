# Create a Lambda function
resource "aws_lambda_function" "rotation_lambda" {
  function_name = "rds_lambda_function"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  //role          = aws_iam_role.lambda_role.arn
  role = aws_iam_role.rotation_lambda_role.arn 

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id] # Add security group
  }

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.rds_credentials.arn
    }
  }
}

# IAM role for the rotation Lambda function
resource "aws_iam_role" "rotation_lambda_role" {
  name = "aalimsee_rotation_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

tags = { Name = "lambda_role", description = "Created by Aaron"}
}

# Attach policies to the rotation Lambda function role
resource "aws_iam_role_policy" "rotation_lambda_policy" {
  role = aws_iam_role.rotation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions for Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
      # Permissions for RDS (required for database access)
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
        #  "rds-db:connect" # Allows Lambda to connect to the RDS instance
        ]
        Resource = aws_db_instance.rds_instance.arn
      },
      # Permissions for CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # Permissions for EC2 (required for VPC-enabled Lambda)
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Allow Secrets Manager to invoke the Lambda function
resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}