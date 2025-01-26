# Ecommerce cloud mini projects


# Repository Purpose


This repository provides ready-to-use mini projects, POVs, and MVP solutions focusing on e-commerce use cases. Cloud computing offers numerous benefits for e-commerce businesses, including scalability, high availability, cost optimization, high agility, and quick time to market. This repository provides practical examples of cloud-native solutions for common e-commerce use cases, such as order processing, inventory management, event-driven scenarios, payment processing, and many more.

The goal is to provide a reference infrastructure architecture for e-commerce businesses looking to migrate to cloud architectures or build new solutions on the cloud.


## Planned Projects
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

### 1. Serverless contact form

**Scenario:** \
The startup e-commerce website currently lacks an efficient way to handle customer inquiries.
When customers submit a contact form, the inquiries are not promptly addressed, leading to delayed responses and poor customer satisfaction. To improve this, the system needs to automatically send an email notification to the support team and also to the customer confirming the inquiry submission.


**Technical Requirement:** \
Implement a serverless contact form for an e-commerce website to collect customer inquiries. 
Host the form on a static website and process form submissions without server management.

** Solution Architecture: ** \
AWS S3: For hosting the static website with the contact form. \
AWS API Gateway: To expose a REST API for form submissions. \
AWS Lambda: To process form submissions and send email notifications. \
Amazon SES: For sending email notifications to the support team and customers.

Diagram

Explanation

High level Implementation Steps

Terraform scripts

conceptual understanding



## Installation
Instructions for installing the project.

## Usage
TODO: Instructions for using the project.

## Contributing
If you would like to report an issue or a topic, please open an issue. If you would like to contribute, please open a pull request.

## License
TODO: Add license information