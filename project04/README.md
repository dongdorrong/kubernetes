# Project 04 - Bottlerocket 기반 보안 강화 EKS 클러스터 🚀

> 컨테이너 최적화 OS와 통합 보안 솔루션을 활용한 엔터프라이즈급 EKS 클러스터

## 📋 프로젝트 개요

- **클러스터 이름**: `bottlerocket`
- **환경**: `dev`
- **리전**: `ap-northeast-2`
- **목적**: 최고 수준의 보안과 운영 효율성을 갖춘 프로덕션 환경 구축

---

## 🎯 핵심 기능

### 🔒 **보안 최적화**
- **Bottlerocket OS**: AWS의 컨테이너 전용 최적화 OS
- **Keycloak**: OpenID Connect 기반 통합 인증 관리 시스템
- **Trivy Operator**: 실시간 보안 취약점 스캐닝
- **KMS 암호화**: 모든 스토리지 및 통신 암호화
- **Network Policy**: 네트워크 레벨 보안 정책

### 🕸️ **서비스 메시**
- **Istio Service Mesh**: Ambient & Sidecar 모드 동시 지원
- **mTLS**: 서비스 간 자동 암호화 통신
- **트래픽 관리**: 지능형 로드 밸런싱 및 라우팅

### 📊 **완전한 관측성**
- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 및 대시보드
- **Loki**: 로그 집계 시스템
- **Alloy**: 통합 관측 데이터 수집 에이전트

### ⚡ **지능형 자동화**
- **Karpenter**: Bottlerocket 최적화 노드 자동 스케일링
- **External DNS**: Route53 자동 DNS 관리
- **Kubecost**: 비용 모니터링 및 최적화

---

## 🔧 Bottlerocket OS 특징

### 핵심 특징
- **AMI 설정**: `bottlerocket@latest` 별칭 사용
- **블록 디바이스**: OS 볼륨(/dev/xvda, 100GB) + gp3 암호화
- **TOML 설정**: 간단한 선언적 구성
- **Admin Container**: 디버깅을 위한 관리 컨테이너 활성화
- **SELinux**: 기본 활성화된 보안 정책
- **읽기 전용 루트**: 불변 인프라 원칙 적용

### 성능 최적화
```yaml
userData: |
  [settings.kubernetes]
  kube-api-qps = 30
  shutdown-grace-period = "30s"
  
  [settings.kubernetes.eviction-hard]
  "memory.available" = "20%"
  
  [settings.host-containers.admin]
  enabled = true
```

---

## 🏗️ 인프라 아키텍처

### 네트워크 구성
- **VPC**: `10.0.0.0/16` (ap-northeast-2a, ap-northeast-2c)
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (ALB, NAT Gateway)
- **Private Subnets**: `10.0.10.0/24`, `10.0.20.0/24` (EKS 워커 노드)
- **Security Groups**: 클러스터/워커 노드 분리
- **DNS**: dongdorrong.com 도메인 사용

### EKS 구성
- **EKS v1.33**: 최신 쿠버네티스 버전
- **EKS Addons**: kube-proxy, CoreDNS, VPC CNI, EBS CSI, Metrics Server, Mountpoint for Amazon S3 CSI
- **IRSA**: IAM Roles for Service Accounts
- **스토리지**: gp3 기본 스토리지 클래스 + S3 기반 ReadWriteMany

### Mountpoint for Amazon S3 CSI 요약
- `terraform/eks_s3.tf`에서 전용 애플리케이션 버킷을 생성하고 `terraform/eks_addon_irsa.tf`에서 해당 버킷 전용 IAM 정책과 역할을 정의해 IRSA로 연결합니다.
- `aws_eks_addon.s3_csi` 리소스가 `aws-mountpoint-s3-csi-driver` 애드온을 설치하며, 톨러레이션 값을 지정해 모든 노드에서 스케줄될 수 있게 했습니다.
- 샘플 정적 PV/PVC/Pod 매니페스트(`terraform/samples/s3-mount-test.yaml`)를 참고해 버킷 이름·prefix만 실제 값으로 바꾸면 바로 RWX 볼륨 테스트가 가능합니다.

---

## 📁 테라폼 구성

```
project04/
├── setAssumeRoleCredential.sh    # AWS 자격 증명 관리
└── terraform/
    ├── main.tf                   # Terraform 메인 설정
    ├── provider.tf               # AWS/Helm/Kubectl 프로바이더
    ├── variables.tf              # 변수 정의
    ├── locals.tf                 # 로컬 변수
    ├── vpc.tf                    # VPC 네트워크 구성
    ├── kms.tf                    # KMS 키 관리
    ├── acm.tf                    # SSL 인증서 관리
    ├── waf.tf                    # WAF 구성
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
    ├── helm_keycloak.tf          # Keycloak 인증 시스템
    ├── helm_security.tf          # Trivy Operator 보안 스캐닝
    └── manifests/                # 쿠버네티스 매니페스트
        ├── alloy-configmap.hcl              # Grafana Alloy 설정
        ├── aws-load-balancer-controller-policy.json
        ├── karpenter-kms-policy.json        # Karpenter KMS 정책
        ├── karpenter-nodeclass.yaml         # Bottlerocket NodeClass
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
cd project04/
./setAssumeRoleCredential.sh
```

**IAM 역할 관리**:
- **terraform-assume-role**: 인프라 관리용 역할 (12시간 세션)
- **eks-assume-role**: EKS 클러스터 관리용 역할 (12시간 세션)

### 2. 인프라 배포
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 3. 클러스터 접속 설정
```bash
aws eks update-kubeconfig --region ap-northeast-2 --name bottlerocket --profile private
```

### 4. 배포 확인
```bash
# Bottlerocket 노드 확인
kubectl get nodes -o=custom-columns=NODE:.metadata.name,OS-IMAGE:.status.nodeInfo.osImage

# 전체 파드 상태 확인
kubectl get pods -A

# Karpenter 노드 확인
kubectl get nodeclaims
kubectl get nodepools
```

---

## 🔍 보안 검증

### Trivy Operator 확인
```bash
# 보안 스캐닝 리포트 확인
kubectl get vulnerabilityreports -A
kubectl get configauditreports -A
kubectl get clustercompliancereports

# Trivy Operator 상태 확인
kubectl get pods -n security
kubectl logs -n security deployment/trivy-operator
```

### Keycloak 인증 확인
```bash
# Keycloak 파드 상태
kubectl get pods -n keycloak

# Keycloak 웹 인터페이스 접속
kubectl port-forward -n keycloak svc/keycloak 8080:80
# 브라우저에서 http://localhost:8080 접속
```

### 보안 정책 확인
```bash
# Network Policy 확인
kubectl get networkpolicies -A

# Security Context 확인
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.securityContext}{"\n"}{end}' -A
```

---

## 📊 모니터링 & 대시보드

### Grafana 접속
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# 브라우저에서 http://localhost:3000 접속
```

### Prometheus 메트릭 확인
```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# 브라우저에서 http://localhost:9090 접속
```

### Kubecost 비용 모니터링
```bash
kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
# 브라우저에서 http://localhost:9090 접속
```

---

## ⚙️ 운영 관리

### 노드 스케일링
```bash
# NodePool 수정으로 스케일링 조정
kubectl edit nodepool default

# 현재 노드 사용률 확인
kubectl top nodes
```

### 로그 확인
```bash
# Loki 로그 쿼리
kubectl port-forward -n monitoring svc/loki 3100:3100

# Alloy 수집 상태 확인
kubectl logs -n monitoring daemonset/alloy
```

### Istio 서비스 메시 관리
```bash
# Istio 상태 확인
kubectl get pods -n istio-system

# Gateway 및 VirtualService 확인
kubectl get gateway,virtualservice -A

# 서비스 메시 트래픽 확인
kubectl get peerauthentications,destinationrules -A
```

---

## 🚫 리소스 제외 정책

### 고자원 소모 애플리케이션
다음 애플리케이션들은 쿠버네티스 클러스터가 아닌 **관리형 서비스 사용 권장**:
- **PostgreSQL** → Amazon RDS
- **Redis** → Amazon ElastiCache
- **Kafka** → Amazon MSK
- **Airflow** → Amazon MWAA

### 경량화 원칙
- 쿠버네티스 클러스터는 애플리케이션 워크로드에 최적화
- 상태 저장(Stateful) 서비스는 관리형 서비스 우선 고려
- 컴퓨팅 리소스 효율성 극대화

---

## 🔧 개선 예정 사항

### 🎯 Phase 1: 핵심 운영 기능
- **Velero**: 백업 및 재해 복구 시스템 추가
- **Cert-Manager**: 자동 SSL 인증서 관리 추가
- **KEDA**: 이벤트 기반 자동 스케일링 구현

### 🎯 Phase 2: 고가용성 구현
- **Thanos**: Prometheus 고가용성 및 장기 보관 구현
- **Loki Distributed**: SingleBinary → Distributed 모드 전환
- **Multi-AZ**: 다중 가용 영역 고가용성 구성

### 🎯 Phase 3: 고급 운영 기능
- **Kubernetes Replicator**: Secret/ConfigMap 자동 복제
- **Chaos Engineering**: 장애 주입 테스트 환경
- **Policy as Code**: OPA/Gatekeeper 정책 자동화

---

## 🔗 관련 링크

- [📖 메인 README](../README.md)
- [📖 Project 03 (Amazon Linux 2023)](../project03/README.md)
- [🔧 Bottlerocket 공식 문서](https://github.com/bottlerocket-os/bottlerocket)
- [🔐 Keycloak 문서](https://www.keycloak.org/documentation)
- [🛡️ Trivy Operator 문서](https://aquasecurity.github.io/trivy-operator/)
- [🕸️ Istio 문서](https://istio.io/latest/docs/)
- [📊 Grafana 대시보드](https://grafana.com/dashboards/)

---

## 🤝 기여 및 피드백

이슈나 개선사항은 메인 저장소에 제출해 주세요:
- 보안 취약점 발견 시 즉시 신고
- 성능 최적화 제안
- 신규 기능 요청
- 문서 개선 사항 