# Ecommerce cloud mini projects


# Repository Purpose


This repository provides ready-to-use mini projects, POVs, and MVP solutions focusing on e-commerce use cases. Cloud computing offers numerous benefits for e-commerce businesses, including scalability, high availability, cost optimization, high agility, and quick time to market. This repository provides practical examples of cloud-native solutions for common e-commerce use cases, such as order processing, inventory management, event-driven scenarios, payment processing, and many more.

The goal is to provide a reference infrastructure architecture for e-commerce businesses looking to migrate to cloud architectures or build new solutions on the cloud.


Each project includes:
- Detailed use case description
- Solution architecture
- Key components and services used
- Implementation steps
- Best practices and tips
- Terraform scripts (where applicable)
- Demo code examples (where applicable)
- Relevant links/explanations to support concept understanding



## E-Commerce Use Cases which are planned to be covered in this repository:
#### PROJECT 1: Serverless contact form
#### PROJECT 2: Product Review Sentiment Analysis
#### PROJECT 3: seller image upload to s3, image recognition, scanning and validation.


********************************************************************************************************************************
********************************************************************************************************************************
## PROJECT 1: Serverless contact form

**Scenario:** \
The startup e-commerce website currently lacks an efficient way to handle customer inquiries.
When customers submit a contact form, the inquiries are not promptly addressed, leading to delayed responses and poor customer satisfaction. To improve this, the system needs to automatically send an email notification to the support team and also to the customer confirming the inquiry submission.


**Technical Requirement:** \
Implement a serverless contact form for an e-commerce website to collect customer inquiries. 
Host the form on a static website and process form submissions without server management.


**Solution Architecture:** \
AWS S3: For hosting the static website with the contact form. \
AWS API Gateway: To expose a REST API for form submissions. \
AWS Lambda: To process form submissions and send email notifications. \
Amazon SES: For sending email notifications to the support team and customers.

Diagram
TODO: Add architecture diagram


**Technical Implementation Plan:** \
Milestones and tasks: \
1. **Create an S3 bucket and host a static website.**
    - Create an S3 bucket using Terraform.
    - Configure the bucket for static website hosting using Terraform.
    - Upload the HTML/CSS/JavaScript files to the bucket along with test form.
    - Set the appropriate permissions for public access using Terraform.

2. **Create an API Gateway endpoint to receive form submissions.**
    - Create a new API in API Gateway using Terraform.
    - Define the resource and method for the contact form endpoint using Terraform.
    - Set up the integration with the Lambda function using Terraform.

3. **Create a Lambda function to process form submissions.**
    - Write the Lambda function code to handle form submissions.
    - Create an IAM role with the necessary permissions for the Lambda function using Terraform.

4. **Configure Amazon SES to send email notifications from Lambda.**
    - setup simple SES emails for sending email notifications.
    - send email to support team and customer from lambda function.

5. ** Add user request (name,email and message) do DynamoDB.**
    - Create a DynamoDB table to store the contact form submissions.
    - Update the Lambda function to save the form data to the DynamoDB table.
    - Verify that the form submissions are correctly stored in the DynamoDB table.

6. **Test end to end**
    - Submit test inquiries through the contact form.
    - Verify the data in the DynamoDB table.
    - Check that email notifications are sent to the support team and customers.

7. **monitoring and logging.**
    - Set up monitoring and logging for the Lambda function and API Gateway using Terraform.
    - Configure alerts for any errors or issues using Terraform. (keep it simple for now)

7. **Best practices and tips.**
    - Follow security best practices for AWS resources.
    - Optimize the Lambda function for performance and cost.
    - Ensure the solution is scalable and maintainable.

8. **Documentation and references.**
    - Update the `README.md` with detailed instructions for installation and usage.
    - Provide a high-level implementation guide and best practices.
    - Include relevant links and references to support concept understanding.


Possible future improvements:
1. use edge location for faster response for different regions. // by creating cloudfront distribution.
2. setting up WAF firewall for security the page and created API gateways.
3. steps for domain mapping and certificate management using aws certificate manager.

## Installation
Instructions for installing the project.

## Usage
TODO: Instructions for using the project.

## Contributing
If you would like to report an issue or a topic, please open an issue. If you would like to contribute, please open a pull request.

## License
TODO: Add license information