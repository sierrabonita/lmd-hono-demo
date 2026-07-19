terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 現状は個人開発なのでローカル管理。将来的にはリモート管理に切り替える予定。
  # S3にstate本体を、DynamoDBでロック(同時apply防止)を管理する構成。
  # backend "s3" {
  #   bucket         = "hono-portfolio-tfstate"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "hono-portfolio-tf-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "app" {
  source = "../../modules/app"

  environment  = "dev"
  project_name = "hono-portfolio"
  aws_region   = "ap-northeast-1"
}
