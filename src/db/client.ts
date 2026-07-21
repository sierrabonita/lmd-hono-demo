import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

const isLocal = !!process.env.DYNAMODB_ENDPOINT

const client = new DynamoDBClient(
  isLocal
    ? {
        endpoint: process.env.DYNAMODB_ENDPOINT,
        region: 'local',
        credentials: {
          accessKeyId: 'dummy',
          secretAccessKey: 'dummy',
        },
      }
    : {}
)

export const ddbDocClient = DynamoDBDocumentClient.from(client)
export const tableName = process.env.TABLE_NAME || 'local-table'
