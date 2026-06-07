# Short-lived IAM identities used by bootstrap-time access tests.
data "aws_iam_policy_document" "access_test_assume_role" {
  count = local.access_test_enabled && local.bastion_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = distinct([
        local.default_admin_arn,
        aws_iam_role.bastion_ssm[0].arn,
      ])
      type = "AWS"
    }
  }
}

resource "aws_iam_role" "access_test" {
  count = local.access_test_enabled && local.bastion_enabled ? 1 : 0

  name               = "${local.project_name}-access-test-role"
  assume_role_policy = data.aws_iam_policy_document.access_test_assume_role[0].json
}

resource "aws_iam_role_policy" "access_test" {
  count = local.access_test_enabled && local.bastion_enabled ? 1 : 0

  name = "${local.project_name}-access-test"
  role = aws_iam_role.access_test[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DescribeEksCluster"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = aws_eks_cluster.this.arn
      },
      {
        Sid      = "ConnectToRdsAsTestUser"
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = "arn:aws:rds-db:${local.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.teleport.resource_id}/${local.access_test_db_user}"
      },
    ]
  })
}

data "aws_iam_policy_document" "teleport_agent_rds_assume_role" {
  count = local.access_test_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.teleport_agent_namespace}:${local.teleport_agent_service_account}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "teleport_agent_rds" {
  count = local.access_test_enabled ? 1 : 0

  name               = "${local.project_name}-teleport-agent-rds-role"
  assume_role_policy = data.aws_iam_policy_document.teleport_agent_rds_assume_role[0].json
}

resource "aws_iam_role_policy" "teleport_agent_rds" {
  count = local.access_test_enabled ? 1 : 0

  name = "${local.project_name}-teleport-agent-rds"
  role = aws_iam_role.teleport_agent_rds[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ConnectToRdsAsTestUser"
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = "arn:aws:rds-db:${local.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.teleport.resource_id}/${local.access_test_db_user}"
      },
      {
        Sid      = "DescribeRdsMetadata"
        Effect   = "Allow"
        Action   = ["rds:DescribeDBInstances"]
        Resource = "*"
      },
    ]
  })
}
