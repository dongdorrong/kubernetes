data "aws_acm_certificate" "this" {
  domain      = var.domain_name
  statuses    = var.statuses
  most_recent = var.most_recent
}
