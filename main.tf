# main.tf
provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach policies for Lambda to access DynamoDB and CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "lambda_dynamodb_access"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = aws_dynamodb_table.contact_form.arn
    }]
  })
}

# Lambda Function
resource "aws_lambda_function" "contact_form" {
  function_name    = "contactFormHandler"
  handler          = "index.handler" # Matches the pre-built zip
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role.arn
  filename         = "lambda_function.zip" # Path to your zip file
  source_code_hash = filebase64sha256("lambda_function.zip")
  memory_size      = 128
  timeout          = 10
}

# DynamoDB Table
resource "aws_dynamodb_table" "contact_form" {
  name           = "ContactForm"
  billing_mode   = "PAY_PER_REQUEST" # On-demand, cost-effective
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "contactFormAPI"
  description = "API for contact form submissions"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "submit"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

# Deployment (just the published version of the API)
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# Stage (defines the environment, like "prod")
resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "prod"
}


# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Output the API URL
output "api_url" {
  value       = "${aws_api_gateway_rest_api.api.execution_arn}/prod/submit"
  description = "URL to invoke the API"
}