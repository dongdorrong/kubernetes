# 테라폼 상태 관리를 위한 AWS 리소스 정의
# 현재는 로컬 상태 관리를 사용하므로 주석 처리
# 추후 팀 협업 시 주석을 해제하여 사용

# # S3 버킷 생성
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "eksstudy-terraform-state"
# 
#   tags = local.common_tags
# }
# 
# # 버킷 버전 관리 활성화
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# 
# # 서버사이드 암호화 설정
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
# 
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
# 
# # S3 버킷 퍼블릭 액세스 차단
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
# 
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
# 
# # DynamoDB 테이블 생성 (상태 잠금용)
# resource "aws_dynamodb_table" "terraform_lock" {
#   name           = "eksstudy-terraform-lock"
#   billing_mode   = "PAY_PER_REQUEST"
#   hash_key       = "LockID"
# 
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# 
#   tags = local.common_tags
# } 