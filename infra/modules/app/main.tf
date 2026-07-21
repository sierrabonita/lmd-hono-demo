# Lambda関数の定義
resource "aws_lambda_function" "hono_lambda" {
  filename         = "../../../deploy.zip"
  function_name    = "${var.project_name}-${var.environment}-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # deploy.zip 直下の index.js の handler
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("../../../deploy.zip")

  environment {
    variables = {
      NODE_ENV   = var.environment == "prod" ? "production" : "development"
      TABLE_NAME = aws_dynamodb_table.main.name
    }
  }
}

# Function URLの設定（CloudFront OAC経由のためIAM認証）
resource "aws_lambda_function_url" "hono_lambda_url" {
  function_name      = aws_lambda_function.hono_lambda.function_name
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

# CloudFrontからのFunction URLアクセスを許可するリソースベースポリシー
resource "aws_lambda_permission" "allow_cloudfront_function_url" {
  statement_id           = "FunctionURLAllowCloudFront"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.hono_lambda.function_name
  principal              = "cloudfront.amazonaws.com"
  function_url_auth_type = "AWS_IAM"
  source_arn             = aws_cloudfront_distribution.main.arn
}

# 2025年10月以降、Function URLの呼び出しには lambda:InvokeFunction も必要
resource "aws_lambda_permission" "allow_cloudfront_invoke_function" {
  statement_id  = "AllowCloudFrontInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hono_lambda.function_name
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.main.arn
}