

import json
import pymysql
import boto3
import os

# Global variables for the database connection and secret data
conn = None
secret_data = None

def get_secret(secret_name, region_name):
    """Retrieve secret data from AWS Secrets Manager."""
    global secret_data  # Add this line to indicate that secret_data is a global variable
    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(response['SecretString'])
        return secret_data
    except Exception as e:
        print(f"Error retrieving secret: {str(e)}")
        raise

def lambda_handler(event, context):
    global conn, secret_data

    # Set the hardcoded values for host, database, and port
    db_host = "aaron-mysql-instance.chheppac9ozc.us-east-1.rds.amazonaws.com" #Replace with Your RDS CLuster Name
    db_name = "mydb"              #Replace with your DB
    db_port = 3306                #Your MySQL port

    # Retrieve the secrets from AWS Secrets Manager
    secret_name = "rds!db-9ac4d634-9ced-4f2b-b17d-d8d712e7a4da" #Your Secret Name
    region_name = "us-east-1"     #Region where your resources are running

    if secret_data is None:
        secret_data = get_secret(secret_name, region_name)

    # Extract username and password from the secret data
    db_username = secret_data['username']
    db_password = secret_data['password']

    if conn is None:
        # Initialize the database connection if not already created
        conn = pymysql.connect(
            host=db_host,
            user=db_username,
            password=db_password,
            database=db_name,
            port=db_port,
            connect_timeout=5
        )

    try:
        return {
            'statusCode': 200,
            'body': json.dumps('Connected to Database successful!')
        }
    except Exception as e:
        # Handle errors
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
    finally:
        # Close the database connection in the finally block to ensure it's always closed
        if conn is not None:
            conn.close()
            conn = None
