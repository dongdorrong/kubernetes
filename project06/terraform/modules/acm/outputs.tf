output "arn" {
  value       = data.aws_acm_certificate.this.arn
  description = "ARN of the located ACM certificate"
}

output "domain_name" {
  value       = data.aws_acm_certificate.this.domain
  description = "Domain name for the ACM certificate"
}

output "status" {
  value       = data.aws_acm_certificate.this.status
  description = "Status of the ACM certificate"
}

output "certificate" {
  value       = data.aws_acm_certificate.this.certificate
  description = "PEM encoded certificate body"
}

output "certificate_chain" {
  value       = data.aws_acm_certificate.this.certificate_chain
  description = "PEM encoded certificate chain"
}
