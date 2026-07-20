#!/bin/bash

# Local DynamoDB endpoint
ENDPOINT_URL="http://localhost:8000"
TABLE_NAME="local-table"

echo "Creating DynamoDB table '$TABLE_NAME' locally..."

AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=PK,AttributeType=S \
        AttributeName=SK,AttributeType=S \
    --key-schema \
        AttributeName=PK,KeyType=HASH \
        AttributeName=SK,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region local

if [ $? -eq 0 ]; then
    echo "Table created successfully!"
else
    echo "Failed to create table. Please ensure 'npm run db:start' is running."
fi
