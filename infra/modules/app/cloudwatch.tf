# CloudWatch ロググループ（Lambdaの実行ログ）
# デフォルトの無期限保存を防ぎ、14日で自動削除してコストを抑えます
resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.hono_lambda.function_name}"
  retention_in_days = 14
}

# CloudWatch アラーム（Lambdaのエラー監視）
# 1分間に1回でもエラーが発生したらアラーム状態になります
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60 # 60秒単位でチェック
  statistic           = "Sum"
  threshold           = 0  # エラー数が0より大きい（つまり1以上）の場合に発火
  alarm_description   = "Lambda関数 ${aws_lambda_function.hono_lambda.function_name} でエラーが発生しました"
  
  dimensions = {
    FunctionName = aws_lambda_function.hono_lambda.function_name
  }

  # alarm_actions = [aws_sns_topic.slack_alerts.arn]
}
