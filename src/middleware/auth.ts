import { jwt } from 'hono/jwt'

export const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-for-local'
export const protectedRoute = jwt({ secret: JWT_SECRET, alg: 'HS256' })
