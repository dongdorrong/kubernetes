locals {
  # 프로젝트 관련 설정
  project_name = "bottlerocketstudy"
  environment  = "dev"
  owner        = "252462902626"

  # VPC 관련 설정
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  subnet_ids           = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  # 보안 설정
  admin_cidrs = ["175.198.62.193/32"]  # EKS API 접근 허용 IP

  # 클러스터 관련 설정
  cluster_name    = local.project_name

  # EKS 워커 노드 이름 형식
  node_name_format = "${local.cluster_name}-node"
  node_tags        = merge({
    Name = local.node_name_format
  })
} 