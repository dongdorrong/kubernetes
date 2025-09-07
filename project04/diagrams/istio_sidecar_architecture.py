#!/usr/bin/env python3
"""
Project 04 - Istio Sidecar Mesh (Simplified)
Sidecar 모드의 핵심 구성 요소만 포함한 간결한 다이어그램
"""

from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS
from diagrams.aws.network import ALB
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service
from diagrams.onprem.network import Istio, Envoy
from diagrams.programming.language import Python
from diagrams.custom import Custom

# 간결한 Istio Sidecar Mesh 다이어그램
with Diagram("Project 04 - Istio Sidecar Mesh", 
             filename="istio_sidecar_architecture", 
             show=False, 
             direction="TB"):
    
    # 외부 트래픽
    alb = ALB("Load Balancer")
    
    # Istio Control Plane
    with Cluster("Istio Control Plane"):
        istiod = Istio("Istiod")
    
    # Gateway
    gateway = Service("Istio Gateway")
    
    # 애플리케이션 with Sidecar
    with Cluster("Applications with Sidecar"):
        app1 = Pod("App 1")
        app2 = Pod("App 2")
        app3 = Pod("App 3")
        sidecar1 = Envoy("Sidecar")
        sidecar2 = Envoy("Sidecar")
        sidecar3 = Envoy("Sidecar")
    
    # 보안 & 트래픽 관리
    with Cluster("Security & Traffic"):
        mtls = Python("mTLS")
        circuit_breaker = Python("Circuit Breaker")
        policies = Python("Policies")
    
    # 연결 관계
    alb >> gateway >> istiod
    istiod >> sidecar1
    istiod >> sidecar2
    istiod >> sidecar3
    gateway >> app1
    gateway >> app2
    gateway >> app3
    sidecar1 >> app1
    sidecar2 >> app2
    sidecar3 >> app3
    mtls >> sidecar1
    mtls >> sidecar2
    mtls >> sidecar3
    circuit_breaker >> sidecar1
    circuit_breaker >> sidecar2
    circuit_breaker >> sidecar3
    policies >> sidecar1
    policies >> sidecar2
    policies >> sidecar3
