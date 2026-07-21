locals {
  # https://... のURLからドメイン部分を抽出
  lambda_domain_name = split("/", aws_lambda_function_url.hono_lambda_url.function_url)[2]
}

resource "aws_cloudfront_origin_access_control" "lambda_oac" {
  name                              = "${var.project_name}-${var.environment}-lambda-oac"
  description                       = "OAC for Lambda Function URL"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} ${var.environment} API Distribution"
  price_class     = "PriceClass_200"

  origin {
    domain_name              = local.lambda_domain_name
    origin_id                = "LambdaOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda_oac.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "LambdaOrigin"
    viewer_protocol_policy = "redirect-to-https"
    
    # API用のため全メソッドを許可
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # マネージドキャッシュポリシー (CachingDisabled)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    
    # マネージドオリジンリクエストポリシー (AllViewerExceptHostHeader)
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
