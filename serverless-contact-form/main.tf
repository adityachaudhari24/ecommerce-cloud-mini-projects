provider "aws" {
  region = "eu-west-1"
  // store creds on your local machine
  shared_credentials_files = ["/Users/aditya.chaudhari/Documents/.aws/credentials"]
}

# Create an S3 bucket for the static website
resource "aws_s3_bucket" "serverless_contact_form" {
  bucket = "ecomm-serverless-contact-form-bucket" # Replace with your desired bucket name
}

# Enable static website hosting on the bucket
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.serverless_contact_form.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  # // redirect all requests to HTTPS
  //TODO : configure later , this is conflicting with error.html
  #   redirect_all_requests_to {
  #       host_name = "ecomm-serverless-contact-form-bucket.s3-website-eu-west-1.amazonaws.com"
  #       protocol  = "https"
  #   }
}

# Set bucket policy to allow public read access
resource "aws_s3_bucket_policy" "serverless_contact_form_policy" {
  bucket = aws_s3_bucket.serverless_contact_form.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.serverless_contact_form.arn}/*"
        //add condition to secureTransport as true by this this we only allow HTTPS traffic
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}

# Block public access settings for the bucket
resource "aws_s3_bucket_public_access_block" "static_website_public_access" {
  bucket = aws_s3_bucket.serverless_contact_form.bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Upload sample index.html and error.html files to the bucket
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.serverless_contact_form.id
  key          = "index.html"
  content      = <<EOF
<html>
  <head>
    <title>Contact Us</title>
    <script>
      function validateForm() {
        var name = document.forms["contactForm"]["name"].value;
        var email = document.forms["contactForm"]["email"].value;
        var message = document.forms["contactForm"]["message"].value;

        if (name == "") {
          alert("Name must be filled out");
          return false;
        }
        if (email == "") {
          alert("Email must be filled out");
          return false;
        }
        if (message == "") {
          alert("Message must be filled out");
          return false;
        }
        return true;
      }
    </script>
  </head>
  <body style="font-family: Arial, sans-serif; margin: 20px;">
    <h1>Contact Us</h1>
    <form name="contactForm" action="https://y367pm1jea.execute-api.eu-west-1.amazonaws.com/prod1/submit-form" onsubmit="return validateForm()" method="post">
      <label for="name">Name:</label><br>
      <input type="text" id="name" name="name" style="width: 100%; padding: 8px; margin: 5px 0;"><br>
      <label for="email">Email:</label><br>
      <input type="text" id="email" name="email" style="width: 100%; padding: 8px; margin: 5px 0;"><br>
      <label for="message">Message:</label><br>
      <textarea id="message" name="message" style="width: 100%; padding: 8px; margin: 5px 0;"></textarea><br>
      <input type="submit" value="Submit" style="padding: 10px 20px; background-color: #4CAF50; color: white; border: none; cursor: pointer;">
    </form>
  </body>
</html>
EOF
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.serverless_contact_form.id
  key          = "error.html"
  content      = <<EOF
<html>
  <head>
    <title>Error</title>
  </head>
  <body>
    <h1>Oops! Something went wrong.</h1>
  </body>
</html>
EOF
  content_type = "text/html"
}

# Output the website endpoint
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.static_website_config.website_endpoint
}

# Create a VPC
resource "aws_vpc" "vpc-contact-form" {
  cidr_block = "10.0.0.0/16"  // CIDR block is a range of IP addresses that define the IP range in your VPC
  enable_dns_support = true
  // this is required to resolve DNS hostnames in the VPC for API gateway endpoint to work properly
  enable_dns_hostnames = true
  // this is required to resolve DNS hostnames in the VPC for API gateway endpoint to work properly
  tags = {
    Name = "ContactFormVPC"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc-contact-form.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "ContactFormPublicSubnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc-contact-form.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "ContactFormPrivateSubnet"
  }
}

# Create an Internet Gateway
// An internet gateway is a VPC component that allows communication between your VPC and the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-contact-form.id
  tags = {
    Name = "ContactFormIGW"
  }
}


# Route Table for Public Subnet
// A route table contains a set of rules, called routes, that are used to determine where network traffic from your subnet or gateway is directed.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc-contact-form.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


//////////////// lamdba code //////////////////////

// Create an IAM role for the Lambda function
# Lambda Execution Role
// below is required to give permission to lambda to execute
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole" // sts:AssumeRole means  the role can be assumed by the AWS Lambda service
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

// Attach the AWSLambdaBasicExecutionRole policy to the Lambda execution role
resource "aws_iam_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles = [aws_iam_role.lambda_exec.name]
  name       = "lambda_exec_policy"
}


// Attach the AWSLambdaVPCAccessExecutionRole policy to the Lambda execution role
resource "aws_iam_policy_attachment" "lambda_vpc_access_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  roles      = [aws_iam_role.lambda_exec.name]
  name       = "lambda_vpc_access_policy"
}

// Create a Lambda function to handle the form submission for now just log the incomming request
resource "aws_lambda_function" "contact_form_lambda" {
  function_name = "contactFormLambda"
  handler       = "index.handler"
  runtime       =  "nodejs18.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda/contact-form.zip"
  source_code_hash = filebase64sha256("lambda/contact-form.zip")

  vpc_config {
    subnet_ids = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.vpc-contact-form.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LambdaSecurityGroup"
  }
}

// Create a Lambda permission to allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.contact_form_api.execution_arn}/*/*"
}

//////////////////////////////////////////////////


/////////// API Gateway code //////////////////////
//create API gateway POST endpoint to store contact form data and trigger a serverless  lambda function
resource "aws_api_gateway_rest_api" "contact_form_api" {
  name        = "ContactFormAPI"
  description = "API Gateway for Contact Form"
}

// Create a resource for the API Gateway
resource "aws_api_gateway_resource" "form-submission" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  parent_id   = aws_api_gateway_rest_api.contact_form_api.root_resource_id
  path_part   = "submit-form"
}

// Create a POST method for the API Gateway
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.form-submission.id
  http_method   = "POST"
  authorization = "NONE"
}

// Create an integration for the POST method to trigger a Lambda function for now just log hello world
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.contact_form_api.id
  resource_id             = aws_api_gateway_resource.form-submission.id
  http_method             = aws_api_gateway_method.post_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.contact_form_lambda.invoke_arn
}

// Create a deployment for the API Gateway
resource "aws_api_gateway_deployment" "contact_form_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
}

// Create a stage for the API Gateway
resource "aws_api_gateway_stage" "contact_form_stage" {
  deployment_id = aws_api_gateway_deployment.contact_form_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  stage_name    = "prod1"
}