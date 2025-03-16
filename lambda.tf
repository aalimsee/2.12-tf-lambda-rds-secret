

resource "aws_security_group" "lambda_sg" {
  name   = "${local.name_prefix}-lambda"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ensure the Lambda function has permission to update the MySQL password.
resource "aws_iam_role" "lambda_rotation_role" {
  name = "${local.name_prefix}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_rotation_policy" {
  name        = "${local.name_prefix}-rotation-policy"
  description = "IAM policy for secret rotation Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.mysql_secret.arn
        //Resource = "arn:aws:secretsmanager:us-east-1:255945442255:secret:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
        ]
        Resource = aws_db_instance.mysql.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:255945442255:dbuser:*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      { # Modify IAM policy to include network interface permissions for Lambda VPC
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          //"ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          //"ec2:DescribeVpcs",
          "ec2:DetachNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_rotation_role.name
  policy_arn = aws_iam_policy.lambda_rotation_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/package.zip"
}

# Deploy a Lambda function that will handle password rotation.
resource "aws_lambda_function" "secret_rotation" {
  function_name = "${local.name_prefix}-secret-rotation"
  role          = aws_iam_role.lambda_rotation_role.arn
  runtime       = "python3.13"
  handler       = "lambda_function.lambda_handler"
  timeout       = 10

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.mysql_secret.arn # pass secret ARN
      RDS_HOST   = aws_db_instance.mysql.address              # pass RDS endpoint
      //EXCLUDE_CHARACTERS = /@"'\
      //EXCLUDE_LOWERCASE = "false"
      //EXCLUDE_NUMBERS = "false"
      //EXCLUDE_PUNCTUATION = "false"
      //EXCLUDE_UPPERCASE = "false"
      //PASSWORD_LENGTH = "32"
      //REQUIRE_EACH_INCLUDED_TYPE = "true"
      //SECRETS_MANAGER_ENDPOINT = https://secretsmanager.us-east-1.amazonaws.com
    }
  }
}
