
import sys
import logging
import pymysql
import os

import json
import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create a Secrets Manager client
def get_secret(secret_arn):
    client = boto3.client('secretsmanager')
    try:
        response = client.get_secret_value(SecretId=secret_arn)
        secret = response['SecretString']
        return json.loads(secret)
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        raise e

def update_secret(secret_arn, new_password):
    client = boto3.client('secretsmanager')
    try:
        secret = get_secret(secret_arn)
        secret['password'] = new_password
        client.put_secret_value(
            SecretId=secret_arn,
            SecretString=json.dumps(secret)
        )
    except ClientError as e:
        print(f"Error updating secret: {e}")
        raise e

def lambda_handler(event, context):
    secret_arn = event['SecretId']
    step = event['ClientRequestToken']
    print(f"Step: {step}")

    if step == "createSecret":
        # Generate a new password
        new_password = "new_random_password"  # Replace with a secure password generator
        update_secret(secret_arn, new_password)
    elif step == "setSecret":
        # Set the new password in the database
        secret = get_secret(secret_arn)
        db_host = secret['host']
        db_user = secret['username']
        db_password = secret['password']
        db_name = secret['dbname']

        connection = pymysql.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        cursor = connection.cursor()
        cursor.execute(f"ALTER USER '{db_user}'@'%' IDENTIFIED BY '{new_password}';")
        connection.commit()
        cursor.close()
        connection.close()
    elif step == "testSecret":
        # Test the new password
        secret = get_secret(secret_arn)
        db_host = secret['host']
        db_user = secret['username']
        db_password = secret['password']
        db_name = secret['dbname']

        connection = pymysql.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        connection.close()
    elif step == "finishSecret":
        # Mark the new secret as active
        client = boto3.client('secretsmanager')
        client.update_secret_version_stage(
            SecretId=secret_arn,
            VersionStage="AWSCURRENT",
            MoveToVersionId=event['ClientRequestToken'],
            RemoveFromVersionId="AWSPREVIOUS"
        )

    return {
        'statusCode': 200,
        'body': json.dumps('Secret rotation completed successfully')
    }