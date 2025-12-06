# # S3 버킷 생성 - 애플리케이션 데이터용
# resource "aws_s3_bucket" "app_data" {
#   bucket = "${local.project_name}-app-data-${random_string.bucket_suffix.result}"
# }

# # S3 버킷 생성을 위한 랜덤 문자열
# resource "random_string" "bucket_suffix" {
#   length  = 8
#   special = false
#   upper   = false
# }