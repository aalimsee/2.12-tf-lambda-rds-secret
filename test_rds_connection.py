import boto3
import json
import pymysql

AWS_REGION = "us-east-1"
""" SECRET_ARN = "arn:aws:secretsmanager:us-east-1:255945442255:secret:aalimsee-mysql-master-secret-sfmjLU" """
SECRET_ARN = "arn:aws:secretsmanager:us-east-1:255945442255:secret:rds!db-c2e007d8-a012-48e2-ac97-95787051a5b2-AyCsra"


def get_secret():
    """Retrieve RDS MySQL credentials from AWS Secrets Manager"""
    secrets_manager_client = boto3.client("secretsmanager", region_name=AWS_REGION)
    response = secrets_manager_client.get_secret_value(SecretId=SECRET_ARN)
    
    secret = json.loads(response["SecretString"])
    print("🔹 Retrieved Secret:", json.dumps(secret, indent=4))  # Debugging: Print the secret
    return secret

def test_mysql_connection():
    """Test connection to the RDS MySQL instance"""
    secret = get_secret()
    
    try:
        conn = pymysql.connect(
            host=secret["host"],
            user=secret["username"],
            password=secret["password"],
            database=secret["dbname"],
            port=int(secret["port"]),
            connect_timeout=10
        )
        print("✅ Successfully connected to RDS MySQL!")
        conn.close()
    except pymysql.MySQLError as e:
        print(f"❌ MySQL Connection Failed: {e}")

if __name__ == "__main__":
    test_mysql_connection()
