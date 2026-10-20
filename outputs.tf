output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.main.arn
}

output "invoke_arn" {
  description = "The ARN to be used for invoking the function from API Gateway."
  value       = aws_lambda_function.main.invoke_arn
}
