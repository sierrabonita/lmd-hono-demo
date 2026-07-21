import { Hono } from 'hono'
import bcrypt from 'bcryptjs'
import { GetCommand } from '@aws-sdk/lib-dynamodb'
import { sign } from 'hono/jwt'
import { ddbDocClient, tableName } from '../db/client'
import { JWT_SECRET } from '../middleware/auth'

const app = new Hono()

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

export default app
