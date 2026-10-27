terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # The local backend is intentional for this beginner capstone. The state
  # file can contain infrastructure metadata and must not be committed.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
