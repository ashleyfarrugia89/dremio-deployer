terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "com.dremio.field.ashleyfarrugia"
    key    = "tfstate"
    region = "us-east-1"
    dynamodb_table = "AFTFState"
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
# get current region
data "aws_region" "current" {}

# provision iam role



