import { serve } from '@hono/node-server'
import { app } from './index.js'

// 開発用サーバーのポート
const port = 3000

console.log(`Starting local development server on http://localhost:${port}`)

serve({
  fetch: app.fetch,
  port
})
