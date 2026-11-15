terraform {
  # Partial config, so that the bucket and key come from -backend-config at init time, see README.md
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }

  required_version = ">= 1.10.0"
}
