terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "louys-terraform-state"                   # 存儲狀態文件的 S3 桶名稱
    key    = "envs/prod/terraform.tfstate"             # 狀態文件的 S3 路徑
    region = "ap-northeast-1"                          # 桶所在區域
    encrypt = true                                     # 啟用加密存儲
    acl     = "private"                                # 設置為私有
    dynamodb_table = "louys-terraform-lock-table"      # 用於鎖定的 DynamoDB 表名稱
  }
}

data "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-secret"
}

data "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds_secret.id
}

locals {
  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string)
}