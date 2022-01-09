provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.1.3"
}


resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "user-travel-history"
  billing_mode   = "PROVISIONED"
  read_capacity    = 1
  write_capacity   = 1
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "N"
  }

  tags = {
    name        = "user-travel-history-table"
    environment = "dev"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "user-travel-history-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "csv_s3_dynamodb_lambda_policy" {
  name = "user-travel-history-lambda-policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.bucket.arn
      },
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.dynamodb-table.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-1:060796484849:*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_function" "function" {
  filename      = "../lambda_function.zip"
  function_name = "lambda_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "user-travel-history-bucket"
  acl    = "private"
  force_destroy = true

  tags = {
    name        = "Travel History for Users in csv format"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_block_public" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.function.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}