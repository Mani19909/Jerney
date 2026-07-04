terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.48.0"
    }
  }
  backend "s3" {
    bucket = "expense-backend-remote"
    key = "Jerney-eks"
    region = "us-east-1"
    dynamodb_table = "remote-locking"
  }
}

# provide authentication here
provider "aws" {
    region = "us-east-1"

    default_tags {
      tags = {
        Project = "Jernery"
        Environment = var.environment
        ManagedBy  = "Terraform"
      }
    }
}


