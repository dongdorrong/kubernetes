# AWS Provider 설정
provider "aws" {
  region  = "ap-northeast-2"
  profile = "private"
  alias   = "private"  # private 프로필용 alias 설정

  # 프로필 사용 확인을 위한 기본 태그 설정
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}