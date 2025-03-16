
# How to Test the Rotation
- Check Secret Rotation Status
    ```aws secretsmanager describe-secret --secret-id <secret-arn> --region us-east-1
    ```
Secret Name: aalimsee-mysql-secret

Look for "RotationEnabled": true

- Trigger Manual Rotation
    ```aws secretsmanager rotate-secret --secret-id <secret-arn> --region us-east-1
    ```

- Retrieve New Password
    ```aws secretsmanager get-secret-value --secret-id <secret-arn> --region us-east-1
    ```

- Summary
Terraform sets up RDS MySQL, Secrets Manager, Lambda, and IAM roles.

Lambda function:
- Retrieves current credentials.
- Generates a new password.
- Updates MySQL master password.
- Stores the new password in AWS Secrets Manager.
- AWS Secrets Manager automatically rotates the secret every 30 days.

🚀 Your RDS MySQL password is now automatically rotated using Lambda! 🎉

# Connect to MySQL Using IAM Authentication
Once IAM authentication is enabled, you can connect using temporary IAM authentication tokens.

1️⃣ Generate an Authentication Token
Run the following AWS CLI command:

```TOKEN=$(aws rds generate-db-auth-token \
  --hostname <RDS_ENDPOINT> \
  --port 3306 \
  --region us-east-1 \
  --username admin)
```

TOKEN=$(aws rds generate-db-auth-token \
  --hostname aalimsee-mysql-instance.chheppac9ozc.us-east-1.rds.amazonaws.com \
  --port 3306 \
  --region us-east-1 \
  --username admin)

2️⃣ Connect to MySQL
Use the token to authenticate:

    ```mysql -h <RDS_ENDPOINT> -P 3306 --ssl-ca=AmazonRootCA1.pem -u admin --password="$TOKEN"
    ```
✅ IAM Authentication is now enabled for RDS MySQL. You can use IAM roles instead of static passwords!

# Test Connection from EC2 (if RDS is in Private Subnet)
If your RDS instance is in a private subnet, you need to test the connection from an EC2 instance located in the same VPC.

Steps:
Launch an EC2 instance in the same VPC and subnet as your RDS instance.
SSH into the EC2 instance.
From the EC2 instance, try connecting to the RDS MySQL database using the same credentials.

    ```mysql -h aalimsee-mysql-instance.chheppac9ozc.us-east-1.rds.amazonaws.com -u admin -p
    ```

This will help you confirm if the issue is related to network configuration or RDS instance setup.

