# Map performance profiles to Lambda configurations
locals {
  lambda_config = {
    sandbox = {
      memory_size        = 128
      timeout            = 10
      log_retention_days = 3
    }
    development = {
      memory_size        = 256
      timeout            = 15
      log_retention_days = 14
    }
    production = {
      memory_size        = 512
      timeout            = 30
      log_retention_days = 90
    }
  }

  # Code comes either inline from the Console form or from the artifacts bucket
  inline       = var.source_code != ""
  artifact_key = "${var.deployed_service}/${var.deployed_service}-latest.zip"

  tags = merge(
    {
      environment = var.performance_profile
      managed_by  = "terraform"
      service     = var.service_name
    },
    var.additional_tags
  )
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Inline code: packaged by Terraform at plan time
data "archive_file" "inline" {
  count = local.inline ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/.build/${var.service_name}.zip"

  source {
    content  = var.source_code
    filename = var.source_filename
  }
}

# Latest package uploaded by the microservice pipeline: a new version triggers a code update
data "aws_s3_object" "package" {
  count = local.inline ? 0 : 1

  bucket = var.artifacts_bucket
  key    = local.artifact_key
}

# Execution role with basic logging permissions
resource "aws_iam_role" "main" {
  name = "${var.service_name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Read/write access to the DynamoDB table. The policy always exists because the ARN is
# usually linked to another resource and known only at apply time: without a table it
# targets a name that cannot exist.
resource "aws_iam_role_policy" "dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
      ]
      Resource = var.dynamodb_table_arn != "" ? var.dynamodb_table_arn : "arn:aws:dynamodb:*:*:table/no-table-configured"
    }]
  })
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${var.service_name}"
  retention_in_days = local.lambda_config[var.performance_profile].log_retention_days

  tags = local.tags
}

resource "aws_lambda_function" "main" {
  function_name = var.service_name
  role          = aws_iam_role.main.arn
  runtime       = var.runtime
  handler       = var.handler

  filename         = local.inline ? data.archive_file.inline[0].output_path : null
  source_code_hash = local.inline ? data.archive_file.inline[0].output_base64sha256 : null

  s3_bucket         = local.inline ? null : var.artifacts_bucket
  s3_key            = local.inline ? null : local.artifact_key
  s3_object_version = local.inline ? null : data.aws_s3_object.package[0].version_id

  memory_size = local.lambda_config[var.performance_profile].memory_size
  timeout     = local.lambda_config[var.performance_profile].timeout

  environment {
    variables = var.environment_variables
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.logs,
    aws_cloudwatch_log_group.main,
  ]
}

# Allow any API Gateway of this account to invoke the function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*/*"
}
