terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# IAMロールの定義（Lambda実行用）
resource "aws_iam_role" "lambda_role" {
  name = "hono-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 基本的な実行権限ポリシー（CloudWatch Logs出力用）のアタッチ
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda関数の定義
resource "aws_lambda_function" "hono_lambda" {
  filename         = "deploy.zip"
  function_name    = "hono-portfolio-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # deploy.zip 直下の index.js の handler
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("deploy.zip")

  environment {
    variables = {
      NODE_ENV = "production"
    }
  }
}

# Function URLの設定（認証なし・CORS許可）
resource "aws_lambda_function_url" "hono_lambda_url" {
  function_name      = aws_lambda_function.hono_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"] # React(Vite)のローカル開発環境や静的サイトからのアクセスを許可
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

# Function URLへのパブリックアクセスを許可するリソースベースポリシー
resource "aws_lambda_permission" "allow_public_function_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.hono_lambda.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# 2025年10月以降、Function URLの呼び出しには lambda:InvokeFunction も必要
resource "aws_lambda_permission" "allow_public_invoke_function" {
  statement_id  = "FunctionURLAllowInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hono_lambda.function_name
  principal     = "*"
}



# 構築されたFunction URLの出力
output "function_url" {
  description = "The URL to invoke the Hono Lambda function"
  value       = aws_lambda_function_url.hono_lambda_url.function_url
}