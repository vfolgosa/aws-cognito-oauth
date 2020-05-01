provider "aws" {
  profile    = var.aws_profile
  region     = var.aws_region
}

terraform {
  backend "s3" {
  bucket = "tf-app"
  key    = "app/tfstate.terraform"
  region = "us-east-1"
  }
  
}

# This is required to get the AWS region via ${data.aws_region.current}.
data "aws_region" "current" {
}

# Define a Lambda function.
resource "aws_lambda_function" "cadastro-function" {
  function_name    = "cadastro"
  filename         = "cadastro.zip"
  handler          = "cadastro"
  source_code_hash = "${base64sha256(filesha256("cadastro.zip"))}"
  role             = "${aws_iam_role.cadastro-role.arn}"
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 1

  depends_on = [aws_iam_role_policy_attachment.cadastro-logs-policy-attachment, aws_cloudwatch_log_group.cadastro-log]
}

#Role
resource "aws_iam_role" "cadastro-role" {
  name               = "cadastro-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": 
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
}
POLICY
}

# Allow API gateway to invoke the cadastro Lambda function.
resource "aws_lambda_permission" "cadastro-permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cadastro-function.arn}"
  principal     = "apigateway.amazonaws.com"
}

# A Lambda function is not a usual public REST API. We need to use AWS API
# Gateway to map a Lambda function to an HTTP endpoint.
resource "aws_api_gateway_resource" "cadastro-resource" {
  rest_api_id = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.cadastro-rest-api.root_resource_id}"
  path_part   = "cadastro"
}

resource "aws_api_gateway_rest_api" "cadastro-rest-api" {
  name = "cadastro"
}

#           GET
# Internet -----> API Gateway
resource "aws_api_gateway_method" "cadastro-get" {
  rest_api_id   = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id   = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "${aws_api_gateway_authorizer.cadastro-authorizer.id}"

  authorization_scopes = ["cadastro-api/list"]

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

#           POST
# Internet -----> API Gateway
resource "aws_api_gateway_method" "cadastro-post" {
  rest_api_id   = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id   = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "${aws_api_gateway_authorizer.cadastro-authorizer.id}"

  authorization_scopes = ["cadastro-api/create"]

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

#           DELETE
# Internet -----> API Gateway
resource "aws_api_gateway_method" "cadastro-delete" {
  rest_api_id   = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id   = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "${aws_api_gateway_authorizer.cadastro-authorizer.id}"

  authorization_scopes = ["cadastro-api/delete"]

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

#              POST
# API Gateway ------> Lambda
# For Lambda the method is always POST and the type is always AWS_PROXY.
#
# The date 2015-03-31 in the URI is just the version of AWS Lambda.
resource "aws_api_gateway_integration" "cadastro-integration-get" {
  rest_api_id             = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id             = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method             = "${aws_api_gateway_method.cadastro-get.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.cadastro-function.arn}/invocations"
}

#              POST
# API Gateway ------> Lambda
# For Lambda the method is always POST and the type is always AWS_PROXY.
#
# The date 2015-03-31 in the URI is just the version of AWS Lambda.
resource "aws_api_gateway_integration" "cadastro-integration-post" {
  rest_api_id             = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id             = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method             = "${aws_api_gateway_method.cadastro-post.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.cadastro-function.arn}/invocations"
}

#              POST
# API Gateway ------> Lambda
# For Lambda the method is always POST and the type is always AWS_PROXY.
#
# The date 2015-03-31 in the URI is just the version of AWS Lambda.
resource "aws_api_gateway_integration" "cadastro-integration-delete" {
  rest_api_id             = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  resource_id             = "${aws_api_gateway_resource.cadastro-resource.id}"
  http_method             = "${aws_api_gateway_method.cadastro-delete.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.cadastro-function.arn}/invocations"
}

# This resource defines the URL of the API Gateway.
resource "aws_api_gateway_deployment" "cadastro_v1" {
  depends_on = [
    aws_api_gateway_integration.cadastro-integration-get,
    aws_api_gateway_integration.cadastro-integration-post,
    aws_api_gateway_integration.cadastro-integration-delete
  ]
  rest_api_id = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  stage_name  = "v1"
}



# cloudwatch log
resource "aws_iam_policy" "cadastro_logging" {
  name        = "cadastro_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cadastro-logs-policy-attachment" {
  role       = "${aws_iam_role.cadastro-role.name}"
  policy_arn = "${aws_iam_policy.cadastro_logging.arn}"
}
resource "aws_cloudwatch_log_group" "cadastro-log" {
  name              = "/aws/lambda/cadastro"
  retention_in_days = 14
}


##Cognito authorizer
data "aws_cognito_user_pools" "cadastro-user-pool" {
  name = "app-user-pool"
}

resource "aws_api_gateway_authorizer" "cadastro-authorizer" {
  name          = "CadastroCognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = "${aws_api_gateway_rest_api.cadastro-rest-api.id}"
  provider_arns = "${data.aws_cognito_user_pools.cadastro-user-pool.arns}"
}

# Set the generated URL as an output. Run `terraform output url` to get this.
output "url" {
  value = "${aws_api_gateway_deployment.cadastro_v1.invoke_url}${aws_api_gateway_resource.cadastro-resource.path}"
}