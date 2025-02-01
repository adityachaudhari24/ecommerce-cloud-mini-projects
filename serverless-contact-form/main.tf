provider "aws" {
  region = var.region
  // store creds on your local machine
  shared_credentials_files = ["/Users/aditya.chaudhari/Documents/.aws/credentials"]
}

# ------------------------- S3 Configuration ------------------------------------------------------
resource "aws_s3_bucket" "contact_form" {
  bucket = "${var.project_name}-bucket" # Replace with your desired bucket name
  force_destroy = true
}

# Enable static website hosting on the bucket
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.contact_form.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.contact_form.id
  key    = "index.html"
  source = local_file.index_html.filename
  content_type = "text/html"
}

resource "aws_s3_bucket_public_access_block" "disable_block_public" {
  bucket = aws_s3_bucket.contact_form.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Set bucket policy to allow public read access
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.contact_form.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.contact_form.arn}/*"
        //add condition to secureTransport as true by this this we only allow HTTPS traffic
        # Condition = {
        #   Bool = {
        #     "aws:SecureTransport" = "true"
        #   }
        # }
      }
    ]
  })
}

// Adding CORS to S3 bucket
resource "aws_s3_bucket_cors_configuration" "contact_form_cors" {
  bucket = aws_s3_bucket.contact_form.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = [aws_api_gateway_deployment.contact_form_deploy.invoke_url]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# ------------------------- API Gateway Configuration -------------------------
// Step 1: Create an api gateway rest api
resource "aws_api_gateway_rest_api" "contact_form_api" {
  name        = "ContactFormAPI"
  description = "API for submitting contact forms"
}

// Step 2: Create a resource for the api gateway
resource "aws_api_gateway_resource" "submit_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  parent_id   = aws_api_gateway_rest_api.contact_form_api.root_resource_id
  path_part   = "submitContactForm"
}

// Step 3: Create a POST method for the api gateway
resource "aws_api_gateway_method" "post_contact" {
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.submit_contact.id
  http_method   = "POST"
  authorization = "NONE"
}
// Step 4: Create an integration for the POST method to trigger a lambda function
resource "aws_api_gateway_integration" "lambda_integration_POST" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.post_contact.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri  = aws_lambda_function.contact_form.invoke_arn
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.post_contact.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [
  aws_api_gateway_integration.lambda_integration_POST
  ]
}
// Step 4.1 defines the response for the POST method, specicies the response to add Access-Control-Allow-Origin header to allow CORS
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.post_contact.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
// Step 4.2 defines the integration response for the POST method, specicies the response to add Access-Control-Allow-Origin header to allow CORS value as * to allow CORS from any origin


//step 5 : Create OPTIONS method for CORS handling
resource "aws_api_gateway_method" "options_contact" {
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.submit_contact.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

//Step 6: Create an integration for the OPTIONS method to return a 200 status code
resource "aws_api_gateway_integration" "lambda_integration_OPTIONS" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  integration_http_method = "OPTIONS"
  passthrough_behavior = "WHEN_NO_MATCH"
  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

// Step 6.2 defines the integration response for the OPTIONS method, specifies the response to add Access-Control-Allow-Origin header to allow CORS value as * to allow CORS from any origin
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

    depends_on = [
        aws_api_gateway_integration.lambda_integration_OPTIONS
    ]
}

// Step 6.1 defines the response for the OPTIONS method, specifies the response to add Access-Control-Allow-Origin header to allow CORS
resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.submit_contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}




# Deploy API Gateway
resource "aws_api_gateway_deployment" "contact_form_deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration_POST,
    aws_api_gateway_integration.lambda_integration_OPTIONS,
    aws_api_gateway_method.options_contact,
    aws_api_gateway_method.post_contact
  ]
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
}

resource "aws_api_gateway_stage" "contact_form_stage" {
  deployment_id = aws_api_gateway_deployment.contact_form_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  stage_name    = "prod"
}

# ------------------------- Dynamo DB -------------------------
resource "aws_dynamodb_table" "contact_requests" {
  name           = "ContactRequests"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }

}

# ------------------------- Lambda Configuration -------------------------
resource "aws_lambda_function" "contact_form" {
  function_name    = "contactFormHandler"
  runtime         = "nodejs18.x"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  filename        = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.contact_requests.name
      SES_ADMIN_EMAIL  = "acc24.aditya@gmail.com"
      SES_CUSTOMER_EMAIL = "chaudhari.aditya24@gmail.com"
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
}

// setting up IAM role for lambda function
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

// this
resource "aws_iam_policy_attachment" "lambda_exec_policy" {
  name       = "lambda_exec_policy"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_exec.name]
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.contact_requests.arn
      },
      {
        Effect = "Allow",
        Action = "ses:SendEmail",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_exec_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_ses_email_identity" "admin_email" {
  email = "acc24.aditya@gmail.com"
}

resource "aws_ses_email_identity" "customer_email" {
  email = "chaudhari.aditya24@gmail.com"
}



resource "local_file" "index_html" {
  content  = templatefile("${path.module}/index.html.tpl", { api_gateway_stage_invoke_url = "${aws_api_gateway_stage.contact_form_stage.invoke_url}/submitContactForm" })
  filename = "${path.module}/index.html"
}


# Output the S3 website URL and API Gateway URL

output "api_gateway_invoke_url" {
  value = aws_api_gateway_deployment.contact_form_deploy.invoke_url
}

output "api_gateway_stage_invoke_url" {
  value = aws_api_gateway_stage.contact_form_stage.invoke_url
}

output "website_url" {
  value = aws_s3_bucket.contact_form.website
}

output "api_url" {
  value = "${aws_api_gateway_deployment.contact_form_deploy.invoke_url}${aws_api_gateway_resource.submit_contact.path}"
}

# # ------------------------- Networking Configuration ------------------------------------------------------
#
# # Create a VPC
# resource "aws_vpc" "vpc-contact-form" {
#   cidr_block = "10.0.0.0/16"  // CIDR block is a range of IP addresses that define the IP range in your VPC
#   enable_dns_support = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "ContactFormVPC"
#   }
# }
#
# # Create a Public Subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.vpc-contact-form.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "${var.region}a"
#   tags = {
#     Name = "ContactFormPublicSubnet"
#   }
# }
#
# # Create a Private Subnet
# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.vpc-contact-form.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "${var.region}a"
#   tags = {
#     Name = "ContactFormPrivateSubnet"
#   }
# }

# # Create an Internet Gateway
# // An internet gateway is a VPC component that allows communication between your VPC and the internet.
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.vpc-contact-form.id
#   tags = {
#     Name = "ContactFormIGW"
#   }
# }


# # Route Table for Public Subnet
# // A route table contains a set of rules, called routes, that are used to determine where network traffic from your subnet or gateway is directed.
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.vpc-contact-form.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
# }

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }


# # ------------------------- Lambda Configuration -------------------------
#
# // Create an IAM role for the Lambda function
# // below is required to give permission to lambda to execute
# resource "aws_iam_role" "lambda_exec" {
#   name = "lambda_exec_role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole" // sts:AssumeRole means  the role can be assumed by the AWS Lambda service
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }
#
# // Attach the AWSLambdaBasicExecutionRole policy to the Lambda execution role
# resource "aws_iam_policy_attachment" "lambda_exec_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   roles = [aws_iam_role.lambda_exec.name]
#   name       = "lambda_exec_policy"
# }
#
# // Attach the AWSLambdaVPCAccessExecutionRole policy to the Lambda execution role
# resource "aws_iam_policy_attachment" "lambda_vpc_access_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
#   roles      = [aws_iam_role.lambda_exec.name]
#   name       = "lambda_vpc_access_policy"
# }
#
# # Security Group for Lambda
# resource "aws_security_group" "lambda_sg" {
#   vpc_id = aws_vpc.vpc-contact-form.id
#
#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   egress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "LambdaSecurityGroup"
#   }
# }
#
#
#
# // Create a Lambda function to handle the form submission and store the data in DynamoDB and trigger an email.
# resource "aws_lambda_function" "contact_form_lambda" {
#   function_name = "contactFormLambda"
#   handler       = "index.handler"
#   runtime       =  "nodejs18.x"
#   role          = aws_iam_role.lambda_exec.arn
#   filename      = "lambda/contact-form.zip"
#   source_code_hash = filebase64sha256("lambda/contact-form.zip")
#
#   vpc_config {
#     subnet_ids = [aws_subnet.private.id]
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }
#   depends_on = [aws_iam_role.lambda_exec,aws_security_group.lambda_sg]
# }
#
#
# // Create a Lambda permission to allow API Gateway to invoke the Lambda function
# resource "aws_lambda_permission" "apigw_invoke_lambda" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.contact_form_lambda.arn
#   principal     = "apigateway.amazonaws.com"
#
#   source_arn = "${aws_api_gateway_rest_api.contact_form_api.execution_arn}/*/*"
#   depends_on = [aws_api_gateway_rest_api.contact_form_api]
# }
#
#
# # ------------------------- API Gateway Configuration -------------------------
# //create API gateway POST endpoint to store contact form data and trigger a serverless  lambda function
# resource "aws_api_gateway_rest_api" "contact_form_api" {
#   name        = "ContactFormAPI"
#   description = "API Gateway for Contact Form"
# }
#
# // Create a resource for the API Gateway
# resource "aws_api_gateway_resource" "form-submission" {
#   rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
#   parent_id   = aws_api_gateway_rest_api.contact_form_api.root_resource_id
#   path_part   = "submit-form"
# }
#
# // Create a POST method for the API Gateway
# resource "aws_api_gateway_method" "post_method" {
#   rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
#   resource_id   = aws_api_gateway_resource.form-submission.id
#   http_method   = "POST"
#   authorization = "NONE"
# }
#
# // Create an integration for the POST method to trigger a Lambda function
# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.contact_form_api.id
#   resource_id             = aws_api_gateway_resource.form-submission.id
#   http_method             = aws_api_gateway_method.post_method.http_method
#   type                    = "AWS_PROXY"
#   integration_http_method = "POST"
#   uri                     = aws_lambda_function.contact_form_lambda.invoke_arn
# }
#
# // Create a deployment for the API Gateway
# resource "aws_api_gateway_deployment" "contact_form_deployment" {
#   depends_on = [aws_api_gateway_integration.lambda_integration]
#   rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
# }
#
# // Create a stage for the API Gateway
# resource "aws_api_gateway_stage" "contact_form_stage" {
#   deployment_id = aws_api_gateway_deployment.contact_form_deployment.id
#   rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
#   stage_name    = "prod1"
# }
#
# output "website_url" {
#   value = "https://${aws_s3_bucket.serverless_contact_form.bucket}.s3-website.${var.region}.amazonaws.com"
# }
#
# output "api_endpoint" {
#   value = "${aws_api_gateway_stage.contact_form_stage.invoke_url}/submit-form"
# }
#
#
# resource "aws_api_gateway_method_response" "post_method_response" {
#   rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
#   resource_id = aws_api_gateway_resource.form-submission.id
#   http_method = aws_api_gateway_method.post_method.http_method
#   status_code = "200"
#
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin" = true
#   }
# }
#
# resource "aws_api_gateway_integration_response" "post_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
#   resource_id = aws_api_gateway_resource.form-submission.id
#   http_method = aws_api_gateway_method.post_method.http_method
#   status_code = aws_api_gateway_method_response.post_method_response.status_code
#
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }


// references
//https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html
