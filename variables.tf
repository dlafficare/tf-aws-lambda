variable "service_name" {
  description = "The name of the service. Used for Lambda function naming."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,64}$", var.service_name))
    error_message = "Service name must be 1-64 characters: letters, numbers, hyphens and underscores."
  }
}

variable "performance_profile" {
  description = "The performance tier selected by the developer (sandbox, development, production). Memory, timeout and log retention are automatically configured based on this profile."
  type        = string

  validation {
    condition     = contains(["sandbox", "development", "production"], var.performance_profile)
    error_message = "Performance profile must be one of: sandbox, development, production."
  }
}

variable "deployed_service" {
  description = "Name of the microservice whose code is deployed in this function. Must match the microservice name in the Console: its pipeline uploads <name>/<name>-latest.zip to the artifacts bucket."
  type        = string
}

variable "artifacts_bucket" {
  description = "The versioned S3 bucket where microservice pipelines upload their packages."
  type        = string
}

variable "runtime" {
  description = "The Lambda runtime."
  type        = string
  default     = "nodejs22.x"
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
  default     = "index.handler"
}

variable "environment_variables" {
  description = "Environment variables passed to the function, as a JSON object (e.g. {\"TABLE_NAME\": \"ref:counter.table_name\"})."
  type        = any
  default     = {}
}

variable "dynamodb_table_arn" {
  description = "Optional ARN of a DynamoDB table the function can read and write. Leave empty for no access."
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply, as a JSON object (e.g. {\"team\": \"backend\"})."
  type        = any
  default     = {}
}
