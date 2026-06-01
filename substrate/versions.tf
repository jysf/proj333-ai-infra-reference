terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }

  backend "s3" {
    bucket       = "tfstate-proj333-ai-infra-716522590236"
    key          = "ai-infra-reference/substrate.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project   = "ai-infra-reference"
      milestone = "m1"
    }
  }
}
