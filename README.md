

# Deployment Features
✅ RDS MySQL Deployment in a private subnet
✅ Secrets Manager Setup to store DB credentials
✅ Lambda Function for Rotation (Python-based)
✅ IAM Policies to securely access RDS & Secrets Manager
✅ Automatic Secret Rotation every 30 days





# Questions and Answers
What’s the differences between SECRET_ARN and MASTER_SECRET_ARN?

  In AWS Secrets Manager, SECRET_ARN and MASTER_SECRET_ARN are often used in the context of managing and rotating secrets, particularly for database credentials. 

Here’s how they differ:

1. SECRET_ARN (User Secret ARN)

- This refers to the ARN (Amazon Resource Name) of the secret that stores the current credentials used by an application or service.
- Typically, this secret contains a username and password for accessing a database.
- This is the secret that gets rotated when you configure automatic secret rotation in AWS Secrets Manager.

2. MASTER_SECRET_ARN (Master Secret ARN)

- This is the ARN of a separate secret that contains master (admin) credentials for a database.
- During secret rotation, AWS may need admin-level access to generate a new user password or perform other privileged operations.
- The MASTER_SECRET_ARN is referenced only when AWS Secrets Manager is configured to rotate user credentials using a privileged account.

**Example Use Case:**
If you configure AWS Secrets Manager to automatically rotate credentials for a database user (SECRET_ARN), it may use MASTER_SECRET_ARN to authenticate as an admin, create a new password for the user, and update the SECRET_ARN with the new credentials.


# Terraform code and Python code

Here's the Terraform code to set up a rotation Lambda function for RDS MySQL secrets in AWS Secrets Manager, along with the Python code for handling PUT, LIST, and DELETE operations on a database table.

1. Terraform Code for Rotation Lambda (rotation_lambda.tf)
This Terraform script:

- Creates a Lambda function for secrets rotation.
- Configures Secrets Manager to rotate the RDS secret using the Lambda function.
- Grants necessary permissions.


2. Python Code for Lambda (lambda_function.py)
This Python code:

- PUT: Inserts a new employee record.
- LIST: Lists all employees.
- DELETE: Deletes an employee by name.

3. Here’s the Terraform code to create an RDS MySQL instance (rds_mysql.tf) for your project. It includes:

- A private subnet for security.
- Secrets Manager integration for storing credentials.
- Security group to allow connections from the necessary resources.



https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/mysql-install-cli.html

sudo dnf install mariadb105
mysql --version
mysql -h <database_host> -u <username> -p <password>
e.g. mysql -h mydbinstance.chheppac9ozc.us-east-1.rds.amazonaws.com -u db_user -p
SHOW DATABASES;

MySQL [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| innodb             |
| mydatabase         |
| mysql              |
| performance_schema |
| sys                |
+--------------------+

MySQL [mydatabase]> show tables;
Empty set (0.000 sec)


Test lambda function:
secret rotation
{
  "SecretId": "arn:aws:secretsmanager:us-east-1:255945442255:secret:rds_credentials_20250301195919517900000001-rqayVI",
  "ClientRequestToken": "test-token",
  "Step": "createSecret"
}

database operations
{
  "Name": "Inception"
}


aaronlim@MacBookAir 2.12-tf-lambda-rds-secret % aws rds describe-db-instances --query 'DBInstances[*].{DB:DBInstanceIdentifier,PubliclyAccessible:PubliclyAccessible}'

[
    {
        "DB": "mydbinstance",
        "PubliclyAccessible": false
    }
]
aaronlim@MacBookAir 2.12-tf-lambda-rds-secret % 

# Check pending version
aws secretsmanager get-secret-value \
    --secret-id aaron-mysql-secret-20250314002614501800000001 \
    --version-stage AWSPENDING

# Update pending to current
aws secretsmanager update-secret-version-stage \
    --secret-id aaron-mysql-secret-20250314002614501800000001 \
    --version-stage AWSCURRENT \
    --remove-from-version-id terraform-20250314002617210400000003

aws secretsmanager update-secret-version-stage \
  --secret-id aaron-mysql-secret-20250314002614501800000001 \
  --version-stage AWSCURRENT \
  --move-to-version-id terraform-20250314002625955300000004 \
  --remove-from-version-id terraform-20250314002617210400000003

# Rotate secrets
  aws secretsmanager rotate-secret \
  --secret-id aaron-mysql-secret-20250314002614501800000001

# To check the rotation status of an AWS Secrets Manager secret using the CLI, use the 
  aws secretsmanager describe-secret \
  --secret-id aaron-mysql-secret-20250314002614501800000001

