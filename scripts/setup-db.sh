#!/bin/bash

# Local DynamoDB endpoint
ENDPOINT_URL="http://localhost:8000"
TABLE_NAME="local-table"

echo "Creating DynamoDB table '$TABLE_NAME' locally..."

aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=PK,AttributeType=S \
        AttributeName=SK,AttributeType=S \
    --key-schema \
        AttributeName=PK,KeyType=HASH \
        AttributeName=SK,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region local \
    --output text > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Table created successfully!"
else
    echo "Table might already exist or DynamoDB Local is not running."
    echo "Please ensure 'docker-compose up -d' is running."
fi
