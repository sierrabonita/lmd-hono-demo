output "function_url" {
  description = "開発環境の Function URL (直接アクセスは制限されています)"
  value       = module.app.function_url
}

output "cloudfront_url" {
  description = "開発環境の CloudFront URL (APIアクセス用)"
  value       = module.app.cloudfront_url
}
