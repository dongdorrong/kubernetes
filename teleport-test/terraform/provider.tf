provider "aws" {
  region  = local.region
  profile = local.profile

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "opentofu"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
