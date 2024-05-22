output "create_order_api_endpoint" {
  description = "Endpoint for the Create Order API"
  value       = "${aws_apigatewayv2_api.create_order_api.api_endpoint}/createorder"
}

output "get_customer_orders_api_endpoint" {
  description = "Endpoint for the Get Customer Orders API"
  value       = "${aws_apigatewayv2_api.get_customer_orders_api.api_endpoint}/getcustomerorders"
}

output "order_queue_url" {
  description = "URL of the Order SQS Queue"
  value       = aws_sqs_queue.order_queue.url
}

output "order_queue_arn" {
  description = "ARN of the Order SQS Queue"
  value       = aws_sqs_queue.order_queue.arn
}
