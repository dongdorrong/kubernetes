output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "alb_controller_policy_arn" {
  description = "Managed policy ARN for ALB controller"
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = aws_iam_role.ebs_csi.arn
}

output "vpc_cni_role_arn" {
  description = "IAM role ARN for VPC CNI"
  value       = aws_iam_role.vpc_cni.arn
}

output "karpenter_node_role_arn" {
  description = "IAM role ARN for Karpenter nodes"
  value       = aws_iam_role.karpenter_node.arn
}

output "karpenter_controller_role_arn" {
  description = "IAM role ARN for Karpenter controller"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_instance_profile" {
  description = "IAM instance profile name for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter.name
}

output "karpenter_kms_key_arn" {
  description = "KMS key ARN used for Karpenter-managed volumes"
  value       = aws_kms_key.karpenter.arn
}
