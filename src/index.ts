import { Hono } from 'hono'
import { handle } from 'hono/aws-lambda'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, PutCommand, GetCommand, ScanCommand } from '@aws-sdk/lib-dynamodb'
import { jwt, sign } from 'hono/jwt'
import bcrypt from 'bcryptjs'

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
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-for-local'
const protectedRoute = jwt({ secret: JWT_SECRET, alg: 'HS256' })
app.get('/', (c) => {
  return c.text('Hello Hono!')
})

app.post('/users', async (c) => {
  try {
    const body = await c.req.json()
    const { id, name, password } = body

    if (!id || !name || !password) {
      return c.json({ error: 'id, name, and password are required' }, 400)
    }

    const hashedPassword = await bcrypt.hash(password, 10)

    await ddbDocClient.send(
      new PutCommand({
        TableName: tableName,
        Item: {
          PK: `USER#${id}`,
          SK: `USER#${id}`,
          id,
          name,
          password: hashedPassword,
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

app.post('/login', async (c) => {
  try {
    const body = await c.req.json()
    const { id, password } = body

    if (!id || !password) {
      return c.json({ error: 'id and password are required' }, 400)
    }

    const result = await ddbDocClient.send(
      new GetCommand({
        TableName: tableName,
        Key: {
          PK: `USER#${id}`,
          SK: `USER#${id}`
        }
      })
    )

    const user = result.Item
    if (!user || !user.password) {
      return c.json({ error: 'Invalid credentials' }, 401)
    }

    const isValid = await bcrypt.compare(password, user.password)
    if (!isValid) {
      return c.json({ error: 'Invalid credentials' }, 401)
    }

    const payload = {
      id: user.id,
      name: user.name,
      exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 // 24 hours
    }
    const token = await sign(payload, JWT_SECRET)

    return c.json({ token, message: 'Login successful' })
  } catch (err: any) {
    console.error(err)
    return c.json({ error: 'Internal Server Error', details: err.message }, 500)
  }
})

app.get('/users/:id', protectedRoute, async (c) => {
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

app.get('/users', protectedRoute, async (c) => {
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
