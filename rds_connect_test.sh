
# only work if resources in public subnet

# test rds connection with password from sercetsmanager
# rds secret_id to be change on every new deployment in script
# rds host address to be change on every new deployment, if needed

# two secrets created with my deployment and this one gives error when used
# secrets= $( aws secretsmanager get-secret-value --secret-id 'aaron-mysql-secret-5' --query SecretString --output text )


#!/bin/bash

# Retrieve secrets from AWS Secrets Manager
secrets=$(aws secretsmanager get-secret-value --secret-id 'rds!db-9ac4d634-9ced-4f2b-b17d-d8d712e7a4da' --query SecretString --output text)

# Extract username and password
username=$(echo $secrets | jq -r '.username')
password=$(echo $secrets | jq -r '.password')

# Debugging: Uncomment the next lines to check the extracted values (remove passwords in production)
echo "Username: $username"
echo "Password: $password"

# Connect to MySQL
mysql -h aaron-mysql-instance.chheppac9ozc.us-east-1.rds.amazonaws.com -u $username -p$password
