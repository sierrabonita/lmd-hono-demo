import { Hono } from 'hono'
import bcrypt from 'bcryptjs'
import { PutCommand, GetCommand, ScanCommand } from '@aws-sdk/lib-dynamodb'
import { ddbDocClient, tableName } from '../db/client'
import { protectedRoute } from '../middleware/auth'

const app = new Hono()

app.post('/', async (c) => {
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

app.get('/:id', protectedRoute, async (c) => {
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

app.get('/', protectedRoute, async (c) => {
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

export default app
