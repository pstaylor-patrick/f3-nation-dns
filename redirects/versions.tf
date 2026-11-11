terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "f3-nation-production-tfstate-522501930613"
    key          = "redirects/terraform.tfstate"
    region       = "us-east-1"
    profile      = "f3-nation-production"
    encrypt      = true
    use_lockfile = true
  }
}

# Redirect infra lives in f3-nation-production.
provider "aws" {
  region  = "us-east-1"
  profile = var.production_profile

  allowed_account_ids = ["522501930613"]

  default_tags {
    tags = {
      Project   = "f3-nation-redirects"
      ManagedBy = "terraform"
      Repo      = "pstaylor-patrick/f3-nation-dns"
    }
  }
}

# Hosted zones live in f3-nation-dns.
provider "aws" {
  alias   = "dns"
  region  = "us-east-1"
  profile = var.dns_profile

  allowed_account_ids = ["538116017554"]
}
