#!/usr/bin/env python3
"""
Project 04 - Security Architecture (Simplified)
핵심 보안 요소만 포함한 간결한 다이어그램
"""

from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS
from diagrams.aws.security import KMS, IAM
from diagrams.k8s.compute import Pod
from diagrams.onprem.security import Vault, Trivy
from diagrams.onprem.monitoring import Prometheus
from diagrams.programming.language import Python
from diagrams.custom import Custom

# 간결한 보안 아키텍처 다이어그램
with Diagram("Project 04 - Security Architecture", 
             filename="security_architecture", 
             show=False, 
             direction="TB"):
    
    # EKS 클러스터
    with Cluster("EKS Cluster"):
        eks = EKS("Control Plane")
        bottlerocket = Custom("Bottlerocket OS", "./icons/bottlerocket.png")
        workloads = [Pod("App 1"),
                    Pod("App 2"),
                    Pod("App 3")]
    
    # AWS 보안 서비스
    with Cluster("AWS Security"):
        kms = KMS("KMS")
        iam = IAM("IAM")
    
    # 보안 도구
    with Cluster("Security Tools"):
        keycloak = Custom("Keycloak", "./icons/keycloak.png")
        trivy = Custom("Trivy", "./icons/trivy.png")
        falco = Custom("Falco", "./icons/falco.png")
    
    # 모니터링
    monitoring = Prometheus("Security Monitoring")
    
    # 연결 관계
    kms >> eks
    iam >> eks
    eks >> bottlerocket >> workloads
    keycloak >> workloads
    trivy >> workloads
    falco >> workloads
    workloads >> monitoring
