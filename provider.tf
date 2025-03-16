terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}