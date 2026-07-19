terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "app" {
  source = "../../modules/app"

  environment  = "prod"
  project_name = "hono-portfolio"
  aws_region   = "ap-northeast-1"
}
