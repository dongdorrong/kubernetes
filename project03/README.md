# Project 03 - 프로덕션급 EKS 클러스터 ⭐

> 엔터프라이즈급 EKS 클러스터 구성 및 운영을 위한 완전한 프로덕션 환경

## 📋 프로젝트 개요

- **클러스터 이름**: `eksstudy`
- **환경**: `dev`
- **리전**: `ap-northeast-2`
- **목적**: 실제 프로덕션 환경에서 사용 가능한 엔터프라이즈급 EKS 클러스터 구축

---

## 🎯 핵심 기능

### 🚀 **최신 기술 스택**
- **EKS v1.31**: 최신 쿠버네티스 버전
- **Amazon Linux 2023**: 최신 컨테이너 호스트 OS
- **Karpenter v1.4.0**: 지능형 노드 자동 스케일링
- **Gateway API**: 차세대 네트워크 라우팅

### 🕸️ **서비스 메시**
- **Istio Service Mesh**: Ambient & Sidecar 모드 동시 지원
- **mTLS**: 서비스 간 자동 암호화 통신
- **트래픽 관리**: 지능형 로드 밸런싱 및 라우팅
- **관측성**: 분산 추적 및 메트릭 자동 수집

### 📊 **완전한 모니터링 스택**
- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 및 대시보드
- **Loki**: 로그 집계 시스템  
- **Alloy**: 통합 관측 데이터 수집 에이전트 (Grafana Agent 후속)

### ⚡ **운영 효율성**
- **External DNS**: Route53 자동 DNS 관리
- **AWS Load Balancer Controller**: ALB/NLB 통합 관리
- **Kubecost**: 비용 모니터링 및 최적화
- **IRSA**: IAM Roles for Service Accounts

---

## 🏗️ 인프라 아키텍처

### 네트워크 구성
- **VPC**: `10.0.0.0/16` (ap-northeast-2a, ap-northeast-2c)
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (ALB, NAT Gateway)
- **Private Subnets**: `10.0.10.0/24`, `10.0.20.0/24` (EKS 워커 노드)
- **Security Groups**: 클러스터/워커 노드 분리
- **DNS**: dongdorrong.com 도메인 사용

### EKS 구성
- **EKS v1.31**: 최신 쿠버네티스 버전
- **EKS Addons**: kube-proxy, CoreDNS, VPC CNI, EBS CSI, Metrics Server
- **보안**: KMS 암호화, IRSA, ACM 인증서
- **스토리지**: gp3 기본 스토리지 클래스

### AWS IAM 역할 관리
- `setAssumeRoleCredential.sh`: terraform-assume-role, eks-assume-role 자동 전환
- **terraform-assume-role**: 인프라 관리용 역할 (12시간 세션)
- **eks-assume-role**: EKS 클러스터 관리용 역할 (12시간 세션)

---

## 📁 테라폼 구성

```
project03/
├── setAssumeRoleCredential.sh    # AWS 자격 증명 관리
└── terraform/
    ├── main.tf                   # Terraform 메인 설정
    ├── provider.tf               # AWS/Helm/Kubectl 프로바이더
    ├── variables.tf              # 변수 정의
    ├── locals.tf                 # 로컬 변수
    ├── vpc.tf                    # VPC 네트워크 구성
    ├── kms.tf                    # KMS 키 관리
    ├── acm.tf                    # SSL 인증서 관리
    ├── eks_cluster.tf            # EKS 클러스터 & 노드 그룹
    ├── eks_cluster_iam.tf        # EKS 클러스터 IAM 역할
    ├── eks_addon.tf              # EKS 애드온 (CNI, CSI, etc.)
    ├── eks_addon_irsa.tf         # IRSA 기반 애드온 IAM
    ├── eks_karpenter.tf          # Karpenter 설치
    ├── eks_karpenter_iam.tf      # Karpenter IAM 역할
    ├── iam_assume_role.tf        # AssumeRole 설정
    ├── helm_management.tf        # Kubecost, External DNS
    ├── helm_external_dns_iam.tf  # External DNS IAM
    ├── helm_kubecost_iam.tf      # Kubecost IAM
    ├── helm_istio_ambient.tf     # Istio Ambient Mesh
    ├── helm_istio_sidecar.tf     # Istio Sidecar Mesh
    ├── helm_monitoring.tf        # Prometheus, Grafana, Loki, Alloy
    └── manifests/                # 쿠버네티스 매니페스트
        ├── alloy-configmap.hcl              # Grafana Alloy 설정
        ├── aws-load-balancer-controller-policy.json
        ├── karpenter-kms-policy.json        # Karpenter KMS 정책
        ├── karpenter-nodeclass.yaml         # Karpenter EC2NodeClass
        ├── karpenter-nodepool.yaml          # Karpenter NodePool
        ├── storageclass.yaml                # gp3 스토리지 클래스
        ├── gateway-api.yaml                 # Gateway API 설정
        ├── istio-gateway.yaml               # Istio Gateway
        ├── ingress-for-addons.yaml          # 애드온용 Ingress
        └── ingress-for-serivces.yaml        # 서비스용 Ingress
```

---

## 🚀 배포 가이드

### 사전 요구사항
- AWS CLI 및 자격 증명 설정
- Terraform >= 1.2.0
- kubectl
- helm
- jq (AssumeRole 스크립트용)

### 1. AWS IAM 역할 설정
```bash
cd project03/
./setAssumeRoleCredential.sh
```

### 2. 인프라 배포
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 3. 클러스터 접속 설정
```bash
aws eks update-kubeconfig --region ap-northeast-2 --name eksstudy --profile private
```

### 4. 배포 확인
```bash
# 노드 상태 확인
kubectl get nodes -o wide

# 전체 파드 상태 확인
kubectl get pods -A

# Karpenter 노드 확인
kubectl get nodeclaims
kubectl get nodepools
```

---

## 📊 모니터링 & 대시보드

### Grafana 접속
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# 브라우저에서 http://localhost:3000 접속
```

**기본 대시보드**:
- Kubernetes Cluster Overview
- Node Exporter Full
- Istio Service Dashboard
- Istio Performance Dashboard
- Loki Logs Dashboard

### Prometheus 메트릭 확인
```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# 브라우저에서 http://localhost:9090 접속
```

**핵심 메트릭**:
- `kube_pod_info`: 파드 정보
- `node_cpu_seconds_total`: CPU 사용률
- `container_memory_usage_bytes`: 메모리 사용률
- `istio_requests_total`: Istio 요청 메트릭

### Kubecost 비용 모니터링
```bash
kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
# 브라우저에서 http://localhost:9090 접속
```

---

## 🕸️ Istio 서비스 메시 관리

### Ambient 모드 확인
```bash
# Ambient 모드 파드 확인
kubectl get pods -n istio-system

# Gateway 상태 확인
kubectl get gateway -A

# 트래픽 정책 확인
kubectl get peerauthentications,destinationrules -A
```

### Sidecar 모드 확인
```bash
# Sidecar 주입 활성화된 네임스페이스
kubectl get namespace -o jsonpath='{range .items[*]}{.metadata.name}: {.metadata.labels.istio-injection}{"\n"}{end}'

# Sidecar 컨테이너 확인
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.containers[*].name}{"\n"}{end}'
```

### 트래픽 관리
```bash
# Virtual Service 확인
kubectl get virtualservice -A

# Destination Rule 확인  
kubectl get destinationrule -A

# Service Entry 확인
kubectl get serviceentry -A
```

---

## ⚙️ Karpenter 노드 관리

### 노드 스케일링 확인
```bash
# 현재 노드 상태
kubectl get nodes --show-labels

# Karpenter 노드 클래스 확인
kubectl get nodeclass

# 노드풀 상태 확인
kubectl get nodepool -o wide

# 스케일링 이벤트 확인
kubectl get events --field-selector=source=karpenter
```

### 노드 리소스 최적화
```bash
# 노드 리소스 사용률
kubectl top nodes

# 파드별 리소스 사용률
kubectl top pods -A

# 노드 스케일링 조정
kubectl edit nodepool default
```

---

## 🔍 로그 및 디버깅

### Loki 로그 쿼리
```bash
# Loki 직접 접속
kubectl port-forward -n monitoring svc/loki 3100:3100

# LogQL 쿼리 예시
{namespace="kube-system"} |= "error"
{app="istio-proxy"} | json | status_code >= 400
```

### Alloy 수집 상태 확인
```bash
# Alloy DaemonSet 상태
kubectl get daemonset -n monitoring alloy

# Alloy 설정 확인
kubectl get configmap -n monitoring alloy-config -o yaml

# Alloy 로그 확인
kubectl logs -n monitoring daemonset/alloy
```

### 클러스터 디버깅
```bash
# 클러스터 이벤트 확인
kubectl get events --sort-by='.lastTimestamp' -A

# 문제 파드 디버깅
kubectl describe pod <pod-name> -n <namespace>

# 리소스 할당 확인
kubectl describe node <node-name>
```

---

## 💰 비용 최적화

### Kubecost 분석
- **리소스 할당**: 네임스페이스별 비용 분석
- **효율성 점검**: 미사용 리소스 식별
- **권장사항**: 인스턴스 타입 최적화 제안

### Karpenter 최적화
- **Spot Instance**: 비용 절약을 위한 Spot 인스턴스 활용
- **적절한 사이징**: 워크로드에 맞는 인스턴스 크기 자동 선택
- **빠른 스케일링**: 불필요한 리소스 빠른 회수

### 모니터링 기반 최적화
```bash
# 비용 효율성 메트릭 확인
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# 리소스 사용률 기반 조정
kubectl top nodes
kubectl top pods --containers -A
```

---

## 🔒 보안 및 규정 준수

### RBAC 관리
```bash
# 역할 및 바인딩 확인
kubectl get roles,rolebindings -A
kubectl get clusterroles,clusterrolebindings

# 사용자 권한 확인
kubectl auth can-i --list --as=<user>
```

### 네트워크 보안
```bash
# Security Group 확인 (AWS 콘솔)
# Network Policy 확인
kubectl get networkpolicies -A

# Istio 보안 정책 확인
kubectl get peerauthentications,authorizationpolicies -A
```

### 암호화 확인
```bash
# KMS 키 사용 확인
kubectl get storageclass -o yaml

# 전송 중 암호화 확인 (Istio mTLS)
kubectl get peerauthentications -A
```

---

## 🔧 트러블슈팅

### 일반적인 문제 해결

#### 노드 스케일링 문제
```bash
# Karpenter 컨트롤러 로그 확인
kubectl logs -n karpenter deployment/karpenter

# NodePool 상태 확인
kubectl describe nodepool default

# EC2 인스턴스 제한 확인 (AWS 콘솔)
```

#### Istio 관련 문제
```bash
# Istiod 상태 확인
kubectl logs -n istio-system deployment/istiod

# Sidecar 주입 확인
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.containers[*].name}{"\n"}{end}'

# Gateway 연결 확인
kubectl describe gateway <gateway-name> -n <namespace>
```

#### 모니터링 스택 문제
```bash
# Prometheus 타겟 확인
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# http://localhost:9090/targets에서 확인

# Grafana 데이터소스 확인
kubectl logs -n monitoring deployment/grafana

# Loki 수집 상태 확인
kubectl logs -n monitoring deployment/loki
```

---

## 🚀 성능 최적화

### 클러스터 수준 최적화
- **노드 그룹 다양화**: 다양한 인스턴스 타입으로 워크로드 최적화
- **스토리지 최적화**: gp3로 스토리지 성능/비용 최적화
- **네트워킹**: VPC CNI prefix delegation 활용

### 애플리케이션 수준 최적화
- **리소스 요청/제한**: 적절한 CPU/Memory 요청량 설정
- **HPA/VPA**: 자동 스케일링 정책 최적화
- **Istio**: 서비스 메시를 통한 트래픽 최적화

---

## 🔗 관련 링크

- [📖 메인 README](../README.md)
- [📖 Project 04 (Bottlerocket)](../project04/README.md)
- [🕸️ Istio 문서](https://istio.io/latest/docs/)
- [⚡ Karpenter 문서](https://karpenter.sh/)
- [📊 Grafana 대시보드](https://grafana.com/dashboards/)
- [💰 Kubecost 문서](https://docs.kubecost.com/)
- [🔍 Prometheus 문서](https://prometheus.io/docs/)

---

## 🤝 기여 및 피드백

이슈나 개선사항은 메인 저장소에 제출해 주세요:
- 성능 최적화 제안
- 신규 기능 요청  
- 운영 경험 공유
- 문서 개선 사항 