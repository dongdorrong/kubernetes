#!/usr/bin/env python3
"""
Project 04 - Istio Ambient Mesh (Simplified)
Ambient 모드의 핵심 구성 요소만 포함한 간결한 다이어그램
"""

from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS
from diagrams.aws.network import ALB
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service
from diagrams.onprem.network import Istio, Envoy
from diagrams.programming.language import Python
from diagrams.custom import Custom

# 간결한 Istio Ambient Mesh 다이어그램
with Diagram("Project 04 - Istio Ambient Mesh", 
             filename="istio_ambient_architecture", 
             show=False, 
             direction="TB"):
    
    # 외부 트래픽
    alb = ALB("Load Balancer")
    
    # Istio Control Plane
    with Cluster("Istio Control Plane"):
        istiod = Istio("Istiod")
        ztunnel = Istio("Ztunnel")
    
    # Gateway
    gateway = Service("Istio Gateway")
    
    # 애플리케이션
    with Cluster("Applications"):
        apps = [Pod("App 1"),
               Pod("App 2"),
               Pod("App 3")]
    
    # 보안 & 트래픽 관리
    with Cluster("Security & Traffic"):
        mtls = Python("mTLS")
        policies = Python("Policies")
    
    # 연결 관계
    alb >> gateway >> istiod
    istiod >> ztunnel >> apps
    gateway >> apps
    mtls >> apps
    policies >> apps
