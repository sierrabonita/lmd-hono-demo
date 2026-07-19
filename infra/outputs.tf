# 構築されたFunction URLの出力
output "function_url" {
  description = "The URL to invoke the Hono Lambda function"
  value       = aws_lambda_function_url.hono_lambda_url.function_url
}
