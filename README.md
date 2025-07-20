# Kubernetes & EKS 실습 저장소

> AWS EKS를 중심으로 한 쿠버네티스 학습, 실습 및 프로덕션 환경 구성을 위한 종합적인 리소스 모음입니다.

## 📚 프로젝트 구조

### 🎯 핵심 프로젝트

| 프로젝트 | 설명 | 주요 기술 | 상세 가이드 |
|----------|------|-----------|-------------|
| **[Project 01](./project01/README.md)** | 기본 EKS 클러스터 구성 | Terraform, EKS, VPC | [📖 상세보기](./project01/README.md) |
| **[Project 02](./project02/README.md)** | 쿠버네티스 실습 환경 | ArgoCD, Helm, ALB Controller | [📖 상세보기](./project02/README.md) |
| **[Project 03](./project03/README.md)** ⭐ | 프로덕션급 EKS 클러스터 (Amazon Linux 2023) | Istio, Karpenter, 모니터링 스택 | [📖 상세보기](./project03/README.md) |
| **[Project 04](./project04/README.md)** 🚀 | 보안 강화 EKS 클러스터 (Bottlerocket) | Bottlerocket OS, Keycloak, Trivy | [📖 상세보기](./project04/README.md) |

### 🛠 EKS 전용 구성

| 디렉토리 | 설명 | 주요 기술 | 상태 |
|----------|------|-----------|------|
| **[eks_argocd/](./eks_argocd/README.md)** | GitOps 기반 지속적 배포 | ArgoCD, GitOps | ✅ 완료 |
| **[eks_istio/](./eks_istio/README.md)** | 서비스 메시 기본 구성 | Istio, Envoy | ✅ 완료 |
| **[eks_jenkins/](./eks_jenkins/README.md)** | Jenkins CI/CD 파이프라인 | Jenkins, Pipeline | ✅ 완료 |
| **[eks_elk/](./eks_elk/README.md)** | 로깅 스택 | Elasticsearch, Logstash, Kibana | ✅ 완료 |
| **[eks_gp/](./eks_gp/README.md)** | 모니터링 스택 | Grafana, Prometheus | ✅ 완료 |
| **[eks_github/](./eks_github/README.md)** | GitHub Actions 통합 | GitHub Actions | 🔄 진행중 |
| **[eks_gitlab/](./eks_gitlab/README.md)** | GitLab CI/CD 통합 | GitLab CI/CD | 🔄 진행중 |

### 🔬 테스트 환경

| 디렉토리 | 설명 | 주요 기술 | 상태 |
|----------|------|-----------|------|
| **[k3-kyverno-test/](./k3-kyverno-test/README.md)** | K3s 정책 엔진 테스트 | K3s, Kyverno, OPA | ✅ 완료 |

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
- **Kubecost**: 비용 모니터링 및 최적화

### Security & Policy
- **Kyverno**: 정책 기반 보안 관리
- **Trivy Operator**: 컨테이너 이미지 보안 취약점 스캐닝
- **AWS IAM**: 세분화된 권한 관리
- **IRSA**: IAM Roles for Service Accounts
- **KMS**: 암호화 키 관리
- **ACM**: SSL/TLS 인증서 관리

### Identity & Access Management
- **Keycloak**: OpenID Connect 기반 통합 인증 시스템
- **AWS IAM**: 클라우드 리소스 접근 제어
- **RBAC**: 쿠버네티스 역할 기반 접근 제어

### Container Runtime & OS
- **Amazon Linux 2023**: 일반 목적 컨테이너 호스트
- **AWS Bottlerocket**: 컨테이너 최적화 OS
- **Containerd**: 컨테이너 런타임

### CI/CD & GitOps
- **ArgoCD**: GitOps 기반 배포 자동화
- **Jenkins**: 지속적 통합/배포
- **GitHub Actions**: GitHub 통합 CI/CD
- **GitLab CI**: GitLab 통합 CI/CD

---

## 🎯 학습 로드맵

### 🥉 초급: 쿠버네티스 기초
1. **[Project 01](./project01/README.md)**: EKS 클러스터 기본 구성 이해
2. **[Project 02](./project02/README.md)**: 기본 쿠버네티스 오브젝트 실습

### 🥈 중급: DevOps 도구 활용
1. **[eks_argocd/](./eks_argocd/README.md)**: GitOps 워크플로우 구축
2. **[eks_jenkins/](./eks_jenkins/README.md)**: CI/CD 파이프라인 구성
3. **[k3-kyverno-test/](./k3-kyverno-test/README.md)**: 정책 기반 보안 관리 실습

### 🥇 고급: 프로덕션 환경 구성
1. **[Project 03](./project03/README.md)**: 엔터프라이즈급 EKS 클러스터 구축
2. **[Project 04](./project04/README.md)**: Bottlerocket 기반 보안 강화 클러스터
3. **[eks_istio/](./eks_istio/README.md)**: 마이크로서비스 통신 관리
4. **통합 모니터링**: 완전한 관측성 스택 구축

---

## 🔧 빠른 시작

### 사전 요구사항
- AWS CLI 및 자격 증명 설정
- Terraform >= 1.2.0
- kubectl
- helm
- jq (AssumeRole 스크립트용)

### 🚀 권장 시작 순서

1. **초보자**: [Project 01](./project01/README.md) → [Project 02](./project02/README.md)
2. **중급자**: [Project 03](./project03/README.md) 바로 시작
3. **고급자**: [Project 04](./project04/README.md)에서 최신 기술 체험

---

## 📊 프로젝트 비교

| 기능 | Project 01 | Project 02 | Project 03 | Project 04 |
|------|------------|------------|------------|------------|
| **목적** | 기본 학습 | 실습 환경 | 프로덕션 환경 | 보안 강화 환경 |
| **OS** | Amazon Linux 2 | Amazon Linux 2 | Amazon Linux 2023 | **Bottlerocket** |
| **EKS 버전** | 기본 | 기본 | **v1.31** | **v1.31** |
| **서비스 메시** | ❌ | ❌ | **Istio** | **Istio** |
| **모니터링** | 기본 | 기본 | **완전한 스택** | **완전한 스택** |
| **보안** | 기본 | 기본 | 고급 | **최고급** |
| **인증** | AWS IAM | AWS IAM | AWS IAM | **Keycloak** |
| **스케일링** | 수동 | 기본 CA | **Karpenter** | **Karpenter** |
| **비용 최적화** | ❌ | ❌ | **Kubecost** | **Kubecost** |

---

## 🤝 기여 방법

1. 이슈 또는 개선사항 제안
2. 새로운 실습 시나리오 추가
3. 문서화 및 가이드 개선
4. 베스트 프랙티스 공유

---

## 📄 라이선스

이 저장소는 학습 및 실습 목적으로 제작되었습니다.