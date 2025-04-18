# AWS Provider 설정
provider "aws" {
  region  = "ap-northeast-2"
  profile = "private"

  # 프로필 사용 확인을 위한 기본 태그 설정
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

# Kubernetes Provider 설정
# EKS 클러스터의 kubernetes API 서버와 통신하기 위한 설정
# aws-auth ConfigMap 생성 및 관리에 사용됨
provider "kubernetes" {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name, "--profile", "private"]
        command     = "aws"
    }
}

# Helm Provider 설정
provider "helm" {
    kubernetes {
        host                   = aws_eks_cluster.this.endpoint
        cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
        
        exec {
            api_version = "client.authentication.k8s.io/v1beta1"
            args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name, "--profile", "private"]
            command     = "aws"
        }
    }
}