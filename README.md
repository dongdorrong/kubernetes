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
- **핵심 기능**:
  - **Istio Service Mesh**: Ambient/Sidecar 모드 지원
  - **완전한 모니터링 스택**: Prometheus, Grafana, Loki, Alloy
  - **Karpenter**: 자동 노드 스케일링
  - **Gateway API**: 차세대 네트워크 라우팅
  - **AWS IAM 통합**: AssumeRole 기반 권한 관리

**테라폼 구성**:
```
terraform/
├── eks_cluster.tf           # EKS 클러스터 기본 구성
├── eks_karpenter.tf         # Karpenter 자동 스케일링
├── helm_istio_ambient.tf    # Istio Ambient Mesh
├── helm_istio_sidecar.tf    # Istio Sidecar Mesh  
├── helm_monitoring.tf       # 통합 모니터링 스택
├── vpc.tf                   # VPC 네트워크 구성
├── acm.tf                   # SSL 인증서 관리
└── manifests/               # 쿠버네티스 매니페스트
```

**AWS IAM 역할 관리**:
- `setAssumeRoleCredential.sh`: terraform-assume-role, eks-assume-role 자동 전환

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
- **Alloy**: 통합 관측 데이터 수집 에이전트

### Security & Policy
- **Kyverno**: 정책 기반 보안 관리
- **AWS IAM**: 세분화된 권한 관리

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
2. **Istio Service Mesh**: 마이크로서비스 통신 관리
3. **통합 모니터링**: 완전한 관측성 스택 구축

---

## 🔧 빠른 시작

### 사전 요구사항
- AWS CLI 및 자격 증명 설정
- Terraform >= 1.0
- kubectl
- helm

### Project 03 배포 (권장)
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
aws eks update-kubeconfig --region ap-northeast-2 --name <cluster-name>

# 4. 배포 확인
kubectl get nodes
kubectl get pods -A
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
| `project03/` | 프로덕션 환경 | Istio, Karpenter, 모니터링 스택 |
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