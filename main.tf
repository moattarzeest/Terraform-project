provider "aws" {
  region = "us-east-1" 
}
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "my-lambda-functions-bucket"
}

resource "aws_s3_bucket_object" "create_order_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "CreateOrderFunction.zip"
  source = "${path.module}/lambdas/CreateOrderFunction.py"
}

resource "aws_s3_bucket_object" "process_order_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "ProcessOrderFunction.zip"
  source = "${path.module}/lambdas/ProcessOrderFunction.py"
}

resource "aws_s3_bucket_object" "update_stock_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "UpdateStockFunction.zip"
  source = "${path.module}/lambdas/UpdateStockFunction.py"
}

resource "aws_s3_bucket_object" "get_customer_orders_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "GetCustomerOrdersFunction.zip"
  source = "${path.module}/lambdas/GetCustomerOrdersFunction.py"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "lambda_exec_policy_attach" {
  name       = "lambda_exec_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_exec_role.name]
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy" "lambda_ssm_policy" {
  name   = "lambda_ssm_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/myapp/db/*"
        ],
      },
    ],
  })
}


resource "aws_lambda_function" "CreateOrderFunction" {
  function_name    = "CreateOrderFunction"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = aws_s3_bucket_object.create_order_lambda.key
  handler          = "CreateOrderFunction.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("${path.module}/lambdas/CreateOrderFunction.py")
}

resource "aws_lambda_function" "ProcessOrderFunction" {
  function_name    = "ProcessOrderFunction"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = aws_s3_bucket_object.process_order_lambda.key
  handler          = "ProcessOrderFunction.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("${path.module}/lambdas/ProcessOrderFunction.py")
}

resource "aws_lambda_function" "UpdateStockFunction" {
  function_name    = "UpdateStockFunction"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = aws_s3_bucket_object.update_stock_lambda.key
  handler          = "UpdateStockFunction.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("${path.module}/lambdas/UpdateStockFunction.py")
}

resource "aws_lambda_function" "GetCustomerOrdersFunction" {
  function_name    = "GetCustomerOrdersFunction"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = aws_s3_bucket_object.get_customer_orders_lambda.key
  handler          = "GetCustomerOrdersFunction.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("${path.module}/lambdas/GetCustomerOrdersFunction.py")
  environment {
    variables = {
      DB_USERNAME = "ssm:/myapp/db/username"
      DB_PASSWORD = "ssm:/myapp/db/password"
      DB_HOST     = "ssm:/myapp/db/host"
      DB_PORT     = "ssm:/myapp/db/port"
    }
  }
}

resource "aws_apigatewayv2_api" "create_order_api" {
  name          = "CreateOrderAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_api" "get_customer_orders_api" {
  name          = "GetCustomerOrdersAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "create_order_integration" {
  api_id             = aws_apigatewayv2_api.create_order_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.CreateOrderFunction.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_customer_orders_integration" {
  api_id             = aws_apigatewayv2_api.get_customer_orders_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.GetCustomerOrdersFunction.invoke_arn
  integration_method = "GET"
}

resource "aws_apigatewayv2_route" "create_order_route" {
  api_id    = aws_apigatewayv2_api.create_order_api.id
  route_key = "POST /createorder"
  target    = "integrations/${aws_apigatewayv2_integration.create_order_integration.id}"
}

resource "aws_apigatewayv2_route" "get_customer_orders_route" {
  api_id    = aws_apigatewayv2_api.get_customer_orders_api.id
  route_key = "GET /getcustomerorders"
  target    = "integrations/${aws_apigatewayv2_integration.get_customer_orders_integration.id}"
}

resource "aws_apigatewayv2_stage" "create_order_stage" {
  api_id      = aws_apigatewayv2_api.create_order_api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "get_customer_orders_stage" {
  api_id      = aws_apigatewayv2_api.get_customer_orders_api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_create_order" {
  statement_id  = "AllowAPIGatewayInvokeCreateOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CreateOrderFunction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.create_order_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_get_customer_orders" {
  statement_id  = "AllowAPIGatewayInvokeGetCustomerOrders"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.GetCustomerOrdersFunction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.get_customer_orders_api.execution_arn}/*/*"
}

resource "aws_sqs_queue" "order_queue" {
  name = "OrderQueue"
}

resource "aws_lambda_event_source_mapping" "process_order_trigger" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.ProcessOrderFunction.arn
  enabled          = true
  batch_size       = 10
}

resource "aws_sqs_queue_policy" "order_queue_policy" {
  queue_url = aws_sqs_queue.order_queue.url
  policy    = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action    = "sqs:SendMessage",
        Resource  = aws_sqs_queue.order_queue.arn
      }
    ]
  })
}