locals {
  # 프로젝트 관련 설정
  project_name = "eksgatewaypoc"
  environment  = "dev"
  owner        = "252462902626"

  # VPC 관련 설정
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  subnet_ids           = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  private_subnet_ids   = aws_subnet.private[*].id
  public_subnet_ids    = aws_subnet.public[*].id

  # 보안 설정
  admin_cidrs = ["49.169.155.28/32"]  # EKS API 접근 허용 IP

  # 운영: 인터넷-facing NLB(NodePort)로 들어오는 트래픽 허용 CIDR
  # - NLB는 클라이언트 Source IP를 보존하므로, 여기에 "실제 접속자 IP 대역"을 넣어야 함
  # - Health check/내부 트래픽을 위해 VPC CIDR도 함께 허용
  gateway_nodeport_ingress_cidrs = distinct(concat(local.admin_cidrs, [local.vpc_cidr]))

  # 클러스터 관련 설정
  cluster_name    = local.project_name

  # EKS 워커 노드 이름 형식
  node_name_format = "${local.cluster_name}-node"
  node_tags        = merge({
    Name = local.node_name_format
  })
} 
