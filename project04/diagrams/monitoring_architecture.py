#!/usr/bin/env python3
"""
Project 04 - Monitoring Architecture (Simplified)
핵심 모니터링 요소만 포함한 간결한 다이어그램
"""

from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS
from diagrams.aws.storage import S3
from diagrams.k8s.compute import Pod
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.logging import Loki
from diagrams.generic.compute import Rack
from diagrams.programming.language import Python
from diagrams.custom import Custom

# 간결한 모니터링 아키텍처 다이어그램
with Diagram("Project 04 - Monitoring Architecture", 
             filename="monitoring_architecture", 
             show=False, 
             direction="TB"):
    
    # EKS 클러스터
    with Cluster("EKS Cluster"):
        eks = EKS("Control Plane")
        apps = [Pod("App 1"),
               Pod("App 2"),
               Pod("App 3")]
    
    # 데이터 수집
    alloy = Custom("Grafana Alloy", "./icons/alloy.png")
    
    # 메트릭 & 로그
    with Cluster("Observability"):
        prometheus = Prometheus("Prometheus")
        loki = Loki("Loki")
        grafana = Grafana("Grafana")
    
    # 알림
    alerts = Python("Alerts")
    
    # 스토리지
    storage = S3("S3 Storage")
    
    # 연결 관계
    eks >> apps >> alloy
    alloy >> prometheus
    alloy >> loki
    prometheus >> grafana
    loki >> grafana
    prometheus >> alerts
    prometheus >> storage
    loki >> storage
