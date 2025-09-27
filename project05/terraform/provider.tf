# AWS Provider 설정
provider "aws" {
  region  = "ap-northeast-2"
  profile = "private"

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes Provider 설정
# EKS 클러스터의 Kubernetes API 서버와 통신하기 위한 설정
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

# Kubectl Provider 설정
provider "kubectl" {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    load_config_file       = false

    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name, "--profile", "private"]
        command     = "aws"
    }
}