# tf-aws-lambda

Lambda function running the package uploaded by a microservice pipeline to the artifacts bucket (`<service>/<service>-latest.zip`), with execution role, log group, optional DynamoDB access and API Gateway invoke permission.

Part of the Mia-Platform Console demo for AWS: the module is consumed by a Software Catalog item (custom resource) and applied through HCP Terraform by the project pipeline.

## Performance profiles

`sandbox`, `development` and `production` select predefined configurations (see `locals` in `main.tf`).

## Inputs

| Name | Description |
|------|-------------|
| `service_name` | The name of the service. Used for Lambda function naming. |
| `performance_profile` | The performance tier selected by the developer (sandbox, development, production). Memory, timeout and log retention are automatically configured based on this profile. |
| `deployed_service` | Name of the microservice whose code is deployed in this function. Must match the microservice name in the Console: its pipeline uploads <name>/<name>-latest.zip to the artifacts bucket. |
| `artifacts_bucket` | The versioned S3 bucket where microservice pipelines upload their packages. |
| `runtime` | The Lambda runtime. |
| `handler` | The function entrypoint in your code. |
| `environment_variables` | Environment variables passed to the function, as a JSON object (e.g. {"TABLE_NAME": "ref:counter.table_name"}). |
| `dynamodb_table_arn` | Optional ARN of a DynamoDB table the function can read and write. Leave empty for no access. |
| `additional_tags` | Additional tags to apply, as a JSON object (e.g. {"team": "backend"}). |

## Outputs

| Name | Description |
|------|-------------|
| `function_name` | The name of the Lambda function. |
| `function_arn` | The ARN of the Lambda function. |
| `invoke_arn` | The ARN to be used for invoking the function from API Gateway. |

## Requirements

Terraform >= 1.0, AWS provider ~> 5.0. Credentials and region come from the environment (`AWS_*` variables).
