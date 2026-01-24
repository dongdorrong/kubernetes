locals {
  project_name = var.project_name != "" ? var.project_name : "teleport-test"
  environment  = var.environment != "" ? var.environment : "dev"
  region       = var.region != "" ? var.region : "ap-northeast-2"
  profile      = var.profile != "" ? var.profile : "private"

  vpc_cidr             = var.vpc_cidr != "" ? var.vpc_cidr : "10.10.0.0/16"
  azs                  = length(var.azs) > 0 ? var.azs : ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : ["10.10.10.0/24", "10.10.20.0/24"]

  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${trimspace(data.http.public_ip.response_body)}/32"]

  cluster_name = local.project_name

  subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  private_subnet_ids = aws_subnet.private[*].id
  public_subnet_ids  = aws_subnet.public[*].id

  eks_version         = var.eks_version != "" ? var.eks_version : "1.29"
  node_instance_types = length(var.node_instance_types) > 0 ? var.node_instance_types : ["t3.medium"]
  node_capacity_type  = var.node_capacity_type != "" ? var.node_capacity_type : "SPOT"
  node_desired_size   = var.node_desired_size > 0 ? var.node_desired_size : 2
  node_min_size       = var.node_min_size > 0 ? var.node_min_size : 2
  node_max_size       = var.node_max_size > 0 ? var.node_max_size : 3

  rds_engine                = var.rds_engine != "" ? var.rds_engine : "postgres"
  rds_engine_version        = var.rds_engine_version != "" ? var.rds_engine_version : data.aws_rds_engine_version.postgres_default.version
  rds_instance_class        = var.rds_instance_class != "" ? var.rds_instance_class : "db.t3.small"
  rds_allocated_storage     = var.rds_allocated_storage > 0 ? var.rds_allocated_storage : 20
  rds_db_name               = var.rds_db_name != "" ? var.rds_db_name : "teleport"
  rds_username              = var.rds_username != "" ? var.rds_username : "teleportadmin"
  rds_port                  = var.rds_port > 0 ? var.rds_port : 5432
  rds_multi_az              = var.rds_multi_az
  rds_backup_retention_days = var.rds_backup_retention_days > 0 ? var.rds_backup_retention_days : 7

  caller_arn              = data.aws_caller_identity.current.arn
  caller_is_assumed_role  = can(regex("^arn:aws:sts::\\d+:assumed-role/.+/.+$", local.caller_arn))
  caller_account_id       = local.caller_is_assumed_role ? element(split(":", local.caller_arn), 4) : null
  caller_assumed_resource = local.caller_is_assumed_role ? element(split(":", local.caller_arn), 5) : null
  caller_role_name        = local.caller_is_assumed_role ? element(split("/", local.caller_assumed_resource), 1) : null
  default_admin_arn       = local.caller_is_assumed_role ? "arn:aws:iam::${local.caller_account_id}:role/${local.caller_role_name}" : local.caller_arn
  admin_principal_arns = length(var.admin_principal_arns) > 0 ? [
    for arn in var.admin_principal_arns : can(regex("^arn:aws:sts::\\d+:assumed-role/.+/.+$", arn)) ? "arn:aws:iam::${element(split(":", arn), 4)}:role/${element(split("/", element(split(":", arn), 5)), 1)}" : arn
  ] : [local.default_admin_arn]

  ssm_endpoint_services = var.ssm_endpoints_enabled ? {
    ssm         = "com.amazonaws.${local.region}.ssm"
    ssmmessages = "com.amazonaws.${local.region}.ssmmessages"
    ec2messages = "com.amazonaws.${local.region}.ec2messages"
  } : {}

  ssm_user_data = <<-EOF
#!/bin/bash
set -euo pipefail

if command -v dnf >/dev/null 2>&1; then
  dnf install -y amazon-ssm-agent git k9s awscli || true
elif command -v yum >/dev/null 2>&1; then
  yum install -y amazon-ssm-agent git k9s awscli || true
fi

if command -v apt >/dev/null 2>&1; then
  apt update -y || true
  apt install -y wget || true
  wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb || true
  apt install -y ./k9s_linux_amd64.deb || true
  rm -f ./k9s_linux_amd64.deb || true
fi

if ! command -v k9s >/dev/null 2>&1; then
  WORKDIR="/home/ec2-user"
  if [ ! -d "$${WORKDIR}" ]; then
    WORKDIR="/root"
  fi
  K9S_URL_BASE="https://github.com/derailed/k9s/releases/latest/download/"
  K9S_URL_FILE="k9s_Linux_amd64.tar.gz"
  curl -L -o "$${WORKDIR}/k9s.tar.gz" "$${K9S_URL_BASE}$${K9S_URL_FILE}"
  tar -xzf "$${WORKDIR}/k9s.tar.gz" -C "$${WORKDIR}"
  install -o root -g root -m 0755 "$${WORKDIR}/k9s" /usr/local/bin/k9s
  rm -f "$${WORKDIR}/k9s.tar.gz" "$${WORKDIR}/k9s"
fi

systemctl enable --now amazon-ssm-agent || true

if ! command -v helm >/dev/null 2>&1; then
  WORKDIR="/home/ec2-user"
  if [ ! -d "$${WORKDIR}" ]; then
    WORKDIR="/root"
  fi
  curl -fsSL -o "$${WORKDIR}/get_helm.sh" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
  chmod 700 "$${WORKDIR}/get_helm.sh"
  "$${WORKDIR}/get_helm.sh"
fi

if ! command -v kubectl >/dev/null 2>&1; then
  WORKDIR="/home/ec2-user"
  if [ ! -d "$${WORKDIR}" ]; then
    WORKDIR="/root"
  fi
  KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
  curl -L -o "$${WORKDIR}/kubectl" "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 "$${WORKDIR}/kubectl" /usr/local/bin/kubectl
fi

WORKDIR="/home/ec2-user"
if [ ! -d "$${WORKDIR}" ]; then
  WORKDIR="/root"
fi
if [ ! -d "$${WORKDIR}/kubernetes" ]; then
  git clone https://github.com/dongdorrong/kubernetes.git "$${WORKDIR}/kubernetes" || true
fi

if command -v aws >/dev/null 2>&1; then
  if id -u ec2-user >/dev/null 2>&1; then
    TARGET_USER="ec2-user"
    TARGET_HOME="/home/ec2-user"
  else
    TARGET_USER="root"
    TARGET_HOME="/root"
  fi
  mkdir -p "$${TARGET_HOME}/.kube"
  aws eks update-kubeconfig --name ${local.cluster_name} --region ${local.region} --kubeconfig "$${TARGET_HOME}/.kube/config" || true
  chown -R "$${TARGET_USER}:$${TARGET_USER}" "$${TARGET_HOME}/.kube" || true
fi
EOF

  node_name_format = "${local.cluster_name}-node"
  node_tags = {
    Name = local.node_name_format
  }

  ec2_enabled       = var.ec2_enabled
  ec2_instance_type = var.ec2_instance_type != "" ? var.ec2_instance_type : "t3.micro"
  ec2_key_name      = var.ec2_key_name != "" ? var.ec2_key_name : null

  bastion_enabled       = var.bastion_enabled
  bastion_instance_type = var.bastion_instance_type != "" ? var.bastion_instance_type : "t3.micro"
  bastion_key_name      = var.bastion_key_name != "" ? var.bastion_key_name : null
}
