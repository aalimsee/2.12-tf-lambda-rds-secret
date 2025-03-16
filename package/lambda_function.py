


import boto3
import pymysql
import os
import json
import logging
import secrets

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    arn = event['SecretId']
    #arn = os.environ['SECRET_ARN']
    token = event['ClientRequestToken']
    step = event['Step']

    metadata = client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        logger.error(f"Secret {arn} is not enabled for rotation")
        raise ValueError(f"Secret {arn} is not enabled for rotation")

    versions = metadata['VersionIdsToStages']
    if token not in versions:
        logger.error(f"Secret version {token} has no stage for rotation of secret {arn}.")
        raise ValueError(f"Secret version {token} has no stage for rotation of secret {arn}.")

    if "AWSCURRENT" in versions[token]:
        logger.info(f"Secret version {token} already set as AWSCURRENT for secret {arn}.")
        return
    elif "AWSPENDING" not in versions[token]:
        logger.error(f"Secret version {token} not set as AWSPENDING for rotation of secret {arn}.")
        raise ValueError(f"Secret version {token} not set as AWSPENDING for rotation of secret {arn}.")

    if step == "createSecret":
        create_secret(arn, token)

    elif step == "setSecret":
        set_secret(arn, token)

    elif step == "testSecret":
        test_secret(arn, token)

    elif step == "finishSecret":
        finish_secret(arn, token)

    else:
        raise ValueError("Invalid step parameter")

def create_secret(arn, token):
    # Generate a new random password
    new_password = secrets.token_urlsafe(32)

    # Get the current secret
    current_secret = client.get_secret_value(SecretId=arn)
    current_secret_dict = json.loads(current_secret['SecretString'])

    # Create a new secret version with the new password
    client.put_secret_value(
        SecretId=arn,
        ClientRequestToken=token,
        SecretString=json.dumps({
            "username": current_secret_dict["username"],
            "password": new_password
        }),
        VersionStages=["AWSPENDING"]
    )
    logger.info(f"Created new secret version for {arn} with AWSPENDING stage.")

def set_secret(arn, token):
    # Get the pending secret
    pending_secret = client.get_secret_value(SecretId=arn, VersionStage="AWSPENDING")
    pending_secret_dict = json.loads(pending_secret['SecretString'])

    # Connect to the RDS MySQL instance and update the password
    try:
        connection = pymysql.connect(
            host=os.environ['RDS_HOST'],
            user=pending_secret_dict["username"],
            password=pending_secret_dict["password"],
            database="mysql"
        )
        with connection.cursor() as cursor:
            cursor.execute(f"ALTER USER '{pending_secret_dict['username']}'@'%' IDENTIFIED BY '{pending_secret_dict['password']}'")
            connection.commit()
        logger.info(f"Updated MySQL password for user {pending_secret_dict['username']}.")
    except Exception as e:
        logger.error(f"Failed to update MySQL password: {e}")
        raise
    finally:
        if connection:
            connection.close()

def test_secret(arn, token):
    # Test the new password by connecting to the database
    pending_secret = client.get_secret_value(SecretId=arn, VersionStage="AWSPENDING")
    pending_secret_dict = json.loads(pending_secret['SecretString'])

    try:
        connection = pymysql.connect(
            host=os.environ['RDS_HOST'],
            user=pending_secret_dict["username"],
            password=pending_secret_dict["password"],
            database="mysql"
        )
        logger.info(f"Successfully tested new password for {arn}.")
    except Exception as e:
        logger.error(f"Failed to test new password: {e}")
        raise
    finally:
        if connection:
            connection.close()

def finish_secret(arn, token):
    # Promote the pending secret to current
    client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=client.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")['VersionId']
    )
    logger.info(f"Promoted secret version {token} to AWSCURRENT for {arn}.")