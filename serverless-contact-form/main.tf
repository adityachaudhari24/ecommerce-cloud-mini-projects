provider "aws" {
  region     = "eu-west-1"
  access_key = "" // Replace with your own
  secret_key = "" // Replace with your own
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
  bucket = aws_s3_bucket.serverless_contact_form.id

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
        var emailPattern = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;

        if (name == "") {
          alert("Name must be filled out");
          return false;
        }
        if (email == "" || !emailPattern.test(email)) {
          alert("Please enter a valid email address");
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
    <form name="contactForm" action="YOUR_API_GATEWAY_ENDPOINT" onsubmit="return validateForm()" method="post">
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