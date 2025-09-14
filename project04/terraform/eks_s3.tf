# S3 버킷 생성 - 애플리케이션 데이터용
resource "aws_s3_bucket" "app_data" {
  bucket = "${local.project_name}-app-data-${random_string.bucket_suffix.result}"
}

# # S3 버킷 버전 관리
# resource "aws_s3_bucket_versioning" "app_data" {
#   bucket = aws_s3_bucket.app_data.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # S3 버킷 서버 측 암호화
# resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
#   bucket = aws_s3_bucket.app_data.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#     bucket_key_enabled = true
#   }
# }

# # S3 버킷 퍼블릭 액세스 차단
# resource "aws_s3_bucket_public_access_block" "app_data" {
#   bucket = aws_s3_bucket.app_data.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# S3 버킷 생성을 위한 랜덤 문자열
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# # S3 버킷 정책 - S3 CSI 드라이버만 접근 허용
# resource "aws_s3_bucket_policy" "app_data" {
#   bucket = aws_s3_bucket.app_data.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowS3CSIAccess"
#         Effect = "Allow"
#         Principal = {
#           AWS = aws_iam_role.s3_csi.arn
#         }
#         Action = [
#           "s3:ListBucket",
#           "s3:GetBucketLocation"
#         ]
#         Resource = aws_s3_bucket.app_data.arn
#       },
#       {
#         Sid    = "AllowS3CSIObjectAccess"
#         Effect = "Allow"
#         Principal = {
#           AWS = aws_iam_role.s3_csi.arn
#         }
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "s3:AbortMultipartUpload",
#           "s3:ListMultipartUploadParts"
#         ]
#         Resource = "${aws_s3_bucket.app_data.arn}/*"
#       }
#     ]
#   })

#   depends_on = [aws_s3_bucket_public_access_block.app_data]
# }