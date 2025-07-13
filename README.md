# Kubernetes & EKS 실습 저장소

> AWS EKS를 중심으로 한 쿠버네티스 학습, 실습 및 프로덕션 환경 구성을 위한 종합적인 리소스 모음입니다.

## 📚 프로젝트 구조

### 🎯 핵심 프로젝트

#### **Project 01** - 기본 EKS 클러스터
- **목적**: EKS 클러스터 기본 구성과 아키텍처 학습
- **구성요소**:
  - `architecture/`: 프로젝트 아키텍처 다이어그램 (.drawio, .png)
  - `resources/`: 컨테이너, 헬름, 스토리지, 테라폼 기본 구성
- **특징**: EKS 클러스터 구축의 기본 개념과 구성 요소 학습

#### **Project 02** - 쿠버네티스 실습 환경
- **목적**: 쿠버네티스 오브젝트 및 도구 실습
- **구성요소**:
  - `practice/argocd/`: GitOps 배포 자동화 실습
  - `practice/container/`: 컨테이너 기본 구성
  - `practice/helm/`: 헬름 차트 실습
  - `practice/setup_alb_controller/`: AWS Load Balancer Controller 설정
  - `practice/terraform/`: 테라폼 기본 실습
- **특징**: 실무에서 자주 사용하는 쿠버네티스 도구들의 실전 활용법

#### **Project 03** - 프로덕션급 EKS 클러스터 ⭐
- **목적**: 엔터프라이즈급 EKS 클러스터 구성 및 운영
- **클러스터 이름**: `eksstudy`
- **환경**: `dev`
- **리전**: `ap-northeast-2`

**핵심 기능**:
- **EKS v1.31**: 최신 쿠버네티스 버전
- **Istio Service Mesh**: Ambient & Sidecar 모드 동시 지원
- **완전한 모니터링 스택**: Prometheus, Grafana, Loki, Alloy 통합
- **Karpenter v1.4.0**: 지능형 노드 자동 스케일링
- **Gateway API**: 차세대 네트워크 라우팅
- **Kubecost**: 비용 모니터링 및 최적화
- **External DNS**: Route53 자동 DNS 관리
- **AWS Load Balancer Controller**: ALB/NLB 통합 관리

**인프라 구성**:
- **VPC**: `10.0.0.0/16` (ap-northeast-2a, ap-northeast-2c)
- **EKS Addons**: kube-proxy, CoreDNS, VPC CNI, EBS CSI, Metrics Server
- **보안**: KMS 암호화, IRSA, ACM 인증서
- **스토리지**: gp3 기본 스토리지 클래스

**테라폼 구성**:
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

**AWS IAM 역할 관리**:
- `setAssumeRoleCredential.sh`: terraform-assume-role, eks-assume-role 자동 전환
- **terraform-assume-role**: 인프라 관리용 역할 (12시간 세션)
- **eks-assume-role**: EKS 클러스터 관리용 역할 (12시간 세션)

**네트워크 구성**:
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (ALB, NAT Gateway)
- **Private Subnets**: `10.0.10.0/24`, `10.0.20.0/24` (EKS 워커 노드)
- **Security Groups**: 클러스터/워커 노드 분리
- **DNS**: dongdorrong.com 도메인 사용

#### **Project 04** - Bottlerocket 기반 EKS 클러스터 🚀
- **목적**: 컨테이너 최적화 OS를 활용한 보안 강화 EKS 클러스터
- **핵심 기능**:
  - **Bottlerocket OS**: AWS의 컨테이너 전용 최적화 OS
  - **향상된 보안**: 읽기 전용 루트 파일시스템, SELinux 기본 활성화
  - **자동 업데이트**: 원자적 OS 업데이트
  - **경량화**: 최소 패키지로 구성된 경량 OS
  - **SSM 통합**: SSH 대신 AWS Systems Manager 세션 사용

**Bottlerocket 특징**:
- **AMI 설정**: `BOTTLEROCKET_x86_64` 타입 사용
- **블록 디바이스**: OS 볼륨(/dev/xvda) + 데이터 볼륨(/dev/xvdb)
- **TOML 설정**: 간단한 선언적 구성
- **Admin Container**: 디버깅을 위한 관리 컨테이너 지원

**설정 예시**:
```yaml
# Karpenter NodeClass
amiSelectorTerms:
  - alias: "bottlerocket@latest"
  
# UserData (TOML 형식)
userData: |
  [settings.kubernetes]
  kube-api-qps = 30
  shutdown-grace-period = "30s"
  
  [settings.host-containers.admin]
  enabled = true
```

**디버깅 방법**:
```bash
# SSM 세션 시작
aws ssm start-session --target i-1234567890abcdef0

# Admin container 접근
sudo sheltie
```

---

### 🛠 EKS 전용 구성

#### DevOps & CI/CD
- **`eks_argocd/`**: GitOps 기반 지속적 배포
- **`eks_jenkins/`**: Jenkins CI/CD 파이프라인
- **`eks_github/`**: GitHub Actions 통합
- **`eks_gitlab/`**: GitLab CI/CD 통합

#### 로깅 & 모니터링  
- **`eks_elk/`**: Elasticsearch, Logstash, Kibana 스택
- **`eks_gp/`**: Grafana, Prometheus 모니터링

#### 서비스 메시
- **`eks_istio/`**: Istio 서비스 메시 기본 구성

---

### 🔬 K3s 테스트 환경

#### 보안 & 정책
- **`k3-kyverno-test/`**: Kyverno 정책 엔진 테스트

---

## 🚀 주요 기술 스택

### Infrastructure as Code
- **Terraform**: 모든 AWS 리소스 관리
- **Helm**: 쿠버네티스 애플리케이션 패키징

### Container Orchestration
- **Amazon EKS**: 관리형 쿠버네티스 서비스
- **K3s**: 경량 쿠버네티스 (테스트 환경)
- **Karpenter**: 지능형 노드 자동 스케일링

### Service Mesh & Networking
- **Istio**: 서비스 메시 (Ambient & Sidecar)
- **AWS Load Balancer Controller**: ALB/NLB 관리
- **Gateway API**: 차세대 네트워크 API

### Monitoring & Observability
- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 및 대시보드
- **Loki**: 로그 집계 시스템
- **Alloy**: 통합 관측 데이터 수집 에이전트 (Grafana Agent 후속)
- **Kubecost**: 비용 모니터링 및 최적화

### Security & Policy
- **Kyverno**: 정책 기반 보안 관리 (K3s 테스트)
- **AWS IAM**: 세분화된 권한 관리
- **IRSA**: IAM Roles for Service Accounts
- **KMS**: 암호화 키 관리
- **ACM**: SSL/TLS 인증서 관리

### DNS & Networking
- **External DNS**: Route53 자동 DNS 관리
- **Gateway API**: Kubernetes 네이티브 네트워크 라우팅
- **AWS Load Balancer Controller**: ALB/NLB 자동 관리

### Container Runtime & OS
- **Amazon Linux 2023**: 일반 목적 컨테이너 호스트 (Project 03)
- **AWS Bottlerocket**: 컨테이너 최적화 OS (Project 04)
- **Containerd**: 컨테이너 런타임

### CI/CD & GitOps
- **ArgoCD**: GitOps 기반 배포 자동화
- **Jenkins**: 지속적 통합/배포
- **GitHub Actions**: GitHub 통합 CI/CD
- **GitLab CI**: GitLab 통합 CI/CD

---

## 🎯 학습 로드맵

### 🥉 초급: 쿠버네티스 기초
1. **Project 01**: EKS 클러스터 기본 구성 이해
2. **Project 02**: 기본 쿠버네티스 오브젝트 실습

### 🥈 중급: DevOps 도구 활용
1. **eks_argocd/**: GitOps 워크플로우 구축
2. **eks_jenkins/**: CI/CD 파이프라인 구성
3. **k3-kyverno-test/**: 정책 기반 보안 관리 실습

### 🥇 고급: 프로덕션 환경 구성
1. **Project 03**: 엔터프라이즈급 EKS 클러스터 구축
2. **Project 04**: Bottlerocket 기반 보안 강화 클러스터
3. **Istio Service Mesh**: 마이크로서비스 통신 관리
4. **통합 모니터링**: 완전한 관측성 스택 구축

---

## 🔧 빠른 시작

### 사전 요구사항
- AWS CLI 및 자격 증명 설정
- Terraform >= 1.2.0
- kubectl
- helm
- jq (AssumeRole 스크립트용)

### Project 03 배포 (Amazon Linux 2023)
```bash
# 1. AWS IAM 역할 설정
cd project03/
./setAssumeRoleCredential.sh

# 2. Terraform 초기화 및 배포
cd terraform/
terraform init
terraform plan
terraform apply

# 3. 클러스터 접속 설정
aws eks update-kubeconfig --region ap-northeast-2 --name eksstudy --profile private

# 4. 배포 확인
kubectl get nodes -o wide
kubectl get pods -A
```

### Project 04 배포 (Bottlerocket OS)
```bash
# 1. AWS IAM 역할 설정
cd project04/
./setAssumeRoleCredential.sh

# 2. Terraform 초기화 및 배포
cd terraform/
terraform init
terraform plan
terraform apply

# 3. 클러스터 접속 설정
aws eks update-kubeconfig --region ap-northeast-2 --name bottlerocket --profile private

# 4. Bottlerocket 노드 확인
kubectl get nodes -o=custom-columns=NODE:.metadata.name,OS-Image:.status.nodeInfo.osImage
```

### 모니터링 스택 확인
```bash
# Grafana 접속
kubectl port-forward -n monitoring svc/grafana 3000:80

# Prometheus 접속  
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

---

## 📋 디렉토리 상세 설명

| 디렉토리 | 설명 | 주요 기술 |
|----------|------|-----------|
| `project01/` | EKS 기본 구성 | Terraform, EKS, VPC |
| `project02/` | 실습 환경 | ArgoCD, Helm, ALB Controller |
| `project03/` | 프로덕션 환경 (Amazon Linux 2023) | Istio, Karpenter, 모니터링 스택 |
| `project04/` | 보안 강화 환경 (Bottlerocket) | Bottlerocket OS, SSM, TOML 설정 |
| `eks_argocd/` | GitOps 배포 | ArgoCD, GitOps |
| `eks_istio/` | 서비스 메시 | Istio, Envoy |
| `eks_jenkins/` | CI/CD | Jenkins, Pipeline |
| `eks_elk/` | 로그 스택 | Elasticsearch, Logstash, Kibana |
| `k3-kyverno-test/` | 정책 관리 | Kyverno, OPA |

---

## 🤝 기여 방법

1. 이슈 또는 개선사항 제안
2. 새로운 실습 시나리오 추가
3. 문서화 및 가이드 개선
4. 베스트 프랙티스 공유

---

## 📄 라이선스

이 저장소는 학습 및 실습 목적으로 제작되었습니다.