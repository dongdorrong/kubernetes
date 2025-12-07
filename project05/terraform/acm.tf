# 2025-04-19 인증서 생성 완료하여 주석 처리
/*
# ACM 인증서 생성
resource "aws_acm_certificate" "cert" {
  domain_name       = "dongdorrong.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 Zone 데이터 가져오기
data "aws_route53_zone" "zone" {
    name         = "dongdorrong.com"
    private_zone = false
}

# DNS 검증을 위한 Route53 레코드 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

# 검증 완료 대기
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
*/

# 2025-05-13 인증서 생성 완료하여 data로 처리
# ACM 인증서 가져오기
data "aws_acm_certificate" "cert" {
  domain   = "dongdorrong.com"
  statuses = ["ISSUED"]
}