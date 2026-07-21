import { Hono } from 'hono'
import { handle } from 'hono/aws-lambda'

import authRoutes from './routes/auth'
import userRoutes from './routes/users'

export const app = new Hono()

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

// ルーティングの登録
app.route('/', authRoutes)
app.route('/users', userRoutes)

export const handler = handle(app)
