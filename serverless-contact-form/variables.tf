# ------------------------- Variables -------------------------
variable "region" {
  //default     = "eu-west-1"
    default     = "us-east-1"
  description = "AWS deployment region"
}

variable "project_name" {
  default     = "serverless-contact-form"
  description = "Project identifier for resource tagging"
}
