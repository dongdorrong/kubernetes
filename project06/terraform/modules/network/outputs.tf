output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the created VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs"
}

output "public_subnet_arns" {
  value       = aws_subnet.public[*].arn
  description = "Public subnet ARNs"
}

output "private_subnet_arns" {
  value       = aws_subnet.private[*].arn
  description = "Private subnet ARNs"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private route table ID"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "NAT gateway ID"
}

output "nat_eip_id" {
  value       = aws_eip.nat.id
  description = "Elastic IP used by NAT"
}
