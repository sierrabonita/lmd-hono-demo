import { Hono } from 'hono'
import { handle } from 'hono/aws-lambda'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, PutCommand, GetCommand, ScanCommand } from '@aws-sdk/lib-dynamodb'

// ローカル開発用にエンドポイントが指定されている場合はそちらを向く
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
const ddbDocClient = DynamoDBDocumentClient.from(client)

export const app = new Hono()

const tableName = process.env.TABLE_NAME || 'local-table'

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

app.post('/users', async (c) => {
  try {
    const body = await c.req.json()
    const { id, name } = body

    if (!id || !name) {
      return c.json({ error: 'id and name are required' }, 400)
    }

    await ddbDocClient.send(
      new PutCommand({
        TableName: tableName,
        Item: {
          PK: `USER#${id}`,
          SK: `USER#${id}`,
          id,
          name,
          createdAt: new Date().toISOString()
        }
      })
    )

    return c.json({ message: 'User created successfully', id }, 201)
  } catch (err: any) {
    console.error(err)
    return c.json({ error: 'Internal Server Error', details: err.message }, 500)
  }
})

app.get('/users/:id', async (c) => {
  try {
    const id = c.req.param('id')
    
    const result = await ddbDocClient.send(
      new GetCommand({
        TableName: tableName,
        Key: {
          PK: `USER#${id}`,
          SK: `USER#${id}`
        }
      })
    )

    if (!result.Item) {
      return c.json({ error: 'User not found' }, 404)
    }

    return c.json(result.Item)
  } catch (err) {
    console.error(err)
    return c.json({ error: 'Internal Server Error' }, 500)
  }
})

app.get('/users', async (c) => {
  try {
    const result = await ddbDocClient.send(
      // TODO: Queryに変更予定
      new ScanCommand({
        TableName: tableName
      })
    )

    return c.json(result.Items || [])
  } catch (err) {
    console.error(err)
    return c.json({ error: 'Internal Server Error' }, 500)
  }
})

export const handler = handle(app)
