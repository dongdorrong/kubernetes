#!/usr/bin/env python3
"""
Project 04 - Bottlerocket EKS Cluster (Simplified)
간결하고 명확한 아키텍처 다이어그램
"""

from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.network import VPC, ALB, Route53
from diagrams.aws.security import KMS, WAF
from diagrams.aws.storage import S3
from diagrams.k8s.compute import Pod
from diagrams.onprem.security import Vault
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.network import Istio
from diagrams.programming.language import Python
from diagrams.custom import Custom

# 간결한 메인 아키텍처 다이어그램
with Diagram("Project 04 - Bottlerocket EKS Cluster", 
             filename="main_architecture", 
             show=False, 
             direction="TB"):
    
    # 외부 접근
    dns = Route53("dongdorrong.com")
    waf = WAF("WAF")
    alb = ALB("Load Balancer")
    
    # VPC 내부
    with Cluster("VPC"):
        with Cluster("EKS Cluster"):
            eks = EKS("Control Plane")
            
            with Cluster("Bottlerocket Nodes"):
                nodes = [EC2("Node 1"),
                        EC2("Node 2"),
                        EC2("Node 3")]
            
            with Cluster("Applications"):
                apps = [Pod("App 1"),
                       Pod("App 2"),
                       Pod("App 3")]
    
    # 서비스 메시
    istio = Istio("Service Mesh")
    
    # 보안
    with Cluster("Security"):
        keycloak = Custom("Keycloak", "./icons/keycloak.png")
        trivy = Custom("Trivy", "./icons/trivy.png")
        falco = Custom("Falco", "./icons/falco.png")
    
    # 모니터링
    with Cluster("Monitoring"):
        prometheus = Prometheus("Prometheus")
        grafana = Grafana("Grafana")
    
    # 스토리지
    storage = S3("S3 Storage")
    kms = KMS("KMS")
    
    # 연결 관계
    dns >> waf >> alb >> eks
    eks >> nodes[0]
    eks >> nodes[1]
    eks >> nodes[2]
    nodes[0] >> apps[0]
    nodes[1] >> apps[1]
    nodes[2] >> apps[2]
    istio >> apps[0]
    istio >> apps[1]
    istio >> apps[2]
    keycloak >> apps[0]
    keycloak >> apps[1]
    keycloak >> apps[2]
    trivy >> apps[0]
    trivy >> apps[1]
    trivy >> apps[2]
    falco >> apps[0]
    falco >> apps[1]
    falco >> apps[2]
    apps[0] >> prometheus
    apps[1] >> prometheus
    apps[2] >> prometheus
    prometheus >> grafana
    apps[0] >> storage
    apps[1] >> storage
    apps[2] >> storage
    kms >> storage
