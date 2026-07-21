# 構築されたFunction URLの出力
output "function_url" {
  description = "The URL to invoke the Hono Lambda function (Direct access not allowed now)"
  value       = aws_lambda_function_url.hono_lambda_url.function_url
}

# CloudFront のドメイン名出力
output "cloudfront_url" {
  description = "The CloudFront Domain Name for API access"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}
