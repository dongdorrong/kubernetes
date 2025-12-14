provider "aws" {
  region  = "ap-northeast-2"
  profile = "private"

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}
