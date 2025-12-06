# Project 04 - Bottlerocket 기반 보안 강화 EKS 클러스터 🚀

> Bottlerocket OS와 Karpenter를 중심으로 최소 구성의 안전한 EKS 클러스터를 테라폼으로 자동화합니다.

## 📋 프로젝트 개요

- **클러스터 이름**: `bottlerocket`
- **환경**: `dev`
- **리전**: `ap-northeast-2`
- **Terraform 상태**: `terraform/tfstate/terraform.tfstate`에 로컬 저장
- **자격 증명 전략**: `setAssumeRoleCredential.sh`로 `terraform-assume-role`과 `eks-assume-role`을 12시간 세션으로 전환

---

## 🧱 현재 Terraform 구성 요약

- Bottlerocket 기반 **EKS 1.33 클러스터** + 관리형 노드 그룹(Spot) + Karpenter 1.4.0
- **2개 AZ**(2a/2c)에 Public/Private 서브넷, NAT 및 공용/내부 로드 밸런서 태그 자동 구성
- **필수 애드온**: kube-proxy, CoreDNS, VPC CNI(IRSA), EBS CSI(IRSA), Metrics Server, AWS Load Balancer Controller(Helm) + `gp3` StorageClass 배포
- **보안**: KMS 기반 Karpenter EBS 암호화, HardenEKS용 GitHub OIDC 연동, Terraform/EKS 관리자 Access Entry + aws-auth ConfigMap 싱크
- **자동화**: Karpenter NodePool/NodeClass, Bottlerocket TOML(UserData) 템플릿, ALB Controller IAM 정책과 서비스 계정 자동 생성

---

## 🔒 Bottlerocket OS 세부 구성

- 관리형 노드 그룹과 Karpenter `EC2NodeClass` 모두 Bottlerocket AMI 별칭(`bottlerocket@latest`)을 사용합니다.
- `terraform/manifests/karpenter-nodeclass.yaml`은 100Gi gp3 루트 디스크, KMS 암호화, admin host container 활성화, QPS 최적화 등을 선언합니다.
- 동일한 UserData를 기반으로 모든 노드가 읽기 전용 루트 파일 시스템과 SELinux 활성화된 상태로 부팅됩니다.

```toml
[settings.kubernetes]
kube-api-qps = 30
shutdown-grace-period = "30s"

[settings.kubernetes.eviction-hard]
"memory.available" = "20%"

[settings.host-containers.admin]
enabled = true
```

---

## 🏗️ 인프라 구성 상세

### 네트워크
- `terraform/vpc.tf`는 `10.0.0.0/16` VPC, 2개의 Public/Private 서브넷, NAT/IGW/라우팅을 생성하며 서브넷에 LB/Karpenter 태그를 자동 부여합니다.
- 클러스터 전용 추가 SG(`cluster_additional`)와 워커 SG(`worker_default`)를 분리해 제어 플레인 및 노드 통신 규칙을 명확히 관리합니다.

### EKS & 노드
- `terraform/eks_cluster.tf`는 EKS 1.33 클러스터를 생성하고 `API_AND_CONFIG_MAP` 인증 모드와 `aws-auth` ConfigMap을 동시에 구성합니다.
- 기본 노드 그룹은 Spot `t3.medium` Bottlerocket 노드 2대를 유지하며, `aws_launch_template`에 커스텀 SG와 태그를 주입합니다.
- `terraform/eks_karpenter*.tf`는 Karpenter 컨트롤러/노드 IAM, 인스턴스 프로필, Helm 릴리스를 선언하고 NodePool 만료/요구 사항을 YAML 템플릿으로 관리합니다.

### 애드온 & 스토리지
- `terraform/eks_addon*.tf`에서 kube-proxy, CoreDNS, VPC CNI, EBS CSI, Metrics Server 애드온을 설치하고 필요한 IRSA 역할과 정책을 함께 정의합니다.
- AWS Load Balancer Controller는 Helm으로 배포되며, `manifests/aws-load-balancer-controller-policy.json`을 기반으로 한 전용 IAM 역할/서비스 계정을 사용합니다.
- `manifests/storageclass.yaml`을 이용해 기본 `gp3` StorageClass를 Kubernetes API에 직접 적용합니다.

### HardenEKS 연동
- `terraform/eks_hardeneks_iam.tf`는 GitHub Actions OIDC 공급자, HardenEKS 전용 IAM 역할/정책, EKS Access Entry, K8s ClusterRole/Binding을 한 번에 구성합니다.
- 결과적으로 `hardeneks:runner` 그룹이 클러스터에 읽기 권한을 가지며, 추가 점검 파이프라인이 필요할 때 즉시 사용할 수 있습니다.

---

## 📁 Terraform 디렉터리 가이드

```
project04/
├── setAssumeRoleCredential.sh         # AssumeRole 전환 스크립트 (jq 필요)
└── terraform/
    ├── main.tf / provider.tf          # 버전 및 프로바이더, 로컬 백엔드
    ├── locals.tf / variables.tf       # 프로젝트/네트워크 공통 값
    ├── vpc.tf                         # VPC·서브넷·NAT·라우팅
    ├── kms.tf                         # Karpenter 전용 KMS 키
    ├── eks_cluster*.tf                # EKS 본체, IAM, Access Entry, aws-auth
    ├── eks_addon*.tf                  # EKS 애드온 + IRSA + ALB Controller
    ├── eks_karpenter*.tf              # Karpenter Helm/IAM/NodePool
    ├── eks_hardeneks_iam.tf           # HardenEKS용 GitHub OIDC + RBAC
    ├── manifests/                     # IAM 정책, StorageClass, Karpenter 템플릿 등
    └── samples/s3-mount-test.yaml     # Mountpoint S3 CSI 실험용 매니페스트
```

> `helm_*.tf`, `waf.tf`, `eks_s3.tf` 등은 현재 주석 처리된 실험/추가 기능용 파일이지만, 역사와 템플릿을 보존하기 위해 함께 관리합니다.

---

## 🚀 배포 절차

### 1. 사전 요구사항
- AWS CLI, Terraform ≥ 1.2, kubectl, helm, jq
- `~/.aws/credentials_cleanAssumeRoleCredential` 템플릿과 `private` 프로파일 사전 구성

### 2. AssumeRole 전환
```bash
cd project04
./setAssumeRoleCredential.sh   # terraform 또는 eks 역할 선택
aws sts get-caller-identity --profile private
```

### 3. Terraform 실행
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. kubeconfig 업데이트
```bash
aws eks update-kubeconfig \
  --region ap-northeast-2 \
  --name bottlerocket \
  --profile private
```

---

## ✅ 배포 후 검증

```bash
# 노드 상태와 OS 확인 (기본 노드 그룹 + Karpenter 노드)
kubectl get nodes -o wide
kubectl get nodeclaims,nodepools

# 필수 애드온 및 ALB Controller
aws eks list-addons --cluster-name bottlerocket --region ap-northeast-2 --profile private
kubectl -n kube-system get deploy aws-load-balancer-controller

# StorageClass 및 EBS CSI
kubectl get storageclass gp3
kubectl -n kube-system get ds ebs-csi-node

# HardenEKS Access Entry 및 RBAC
aws eks list-access-entries --cluster-name bottlerocket --region ap-northeast-2 --profile private \
  | jq '.accessEntries[] | select(.userName=="hardeneks-runner")'
kubectl get clusterrole hardeneks-runner
kubectl get clusterrolebinding hardeneks-runner-binding
```

필요 시 `samples/s3-mount-test.yaml`을 참고해 Mountpoint S3 CSI 애드온을 재활성화한 뒤 RWX 워크로드를 검증할 수 있습니다.

---

## 💤 주석 처리된 모듈 요약

- **서비스 메시 & 게이트웨이** (`helm_istio_*.tf`, `manifests/gateway-api.yaml`, `manifests/ingress-for-*.yaml`): Istio Ambient/Sidecar, Gateway API, WAF 연동 시 사용할 템플릿이 남아 있습니다.
- **관측/로깅 스택** (`helm_monitoring.tf`, `manifests/alloy-configmap.hcl`): Prometheus, Grafana, Loki, Grafana Alloy 구성이 템플릿 형태로 보관되어 있습니다.
- **보안 & 관리 애드온** (`helm_security.tf`, `helm_management.tf`, `helm_external_dns_iam.tf`, `helm_kubecost_iam.tf`): Trivy Operator, Falco, Cert-Manager, Kubecost, External-DNS, Velero 등의 선언이 필요 시 주석 해제만으로 재사용 가능합니다.
- **애플리케이션 플랫폼** (`helm_deployment.tf`, `helm_keycloak.tf`, `helm_gitea.tf`): KEDA, Argo CD, Keycloak, Gitea와 같은 도구 설치 예제가 포함되어 있습니다.
- **스토리지 실험** (`eks_s3.tf`, `manifests/s3-csi-policy.json`, `samples/s3-mount-test.yaml`): Mountpoint for Amazon S3 CSI 드라이버와 IAM 정책 템플릿이 존재합니다.
- **네트워크 보안** (`waf.tf`, `acm.tf`): ACM 발급 스크립트와 WAF Web ACL 템플릿이 비활성화 상태로 남아 있습니다.

주석 블록을 해제하고 변수만 조정하면 모듈별로 빠르게 실험 환경을 확장할 수 있도록 작성되어 있으니, README의 “향후 우선과제”를 참고해 활성화 순서를 결정하세요.

---

## 🔭 향후 우선과제 제안

1. **Mountpoint S3 CSI & RWX 테스트**: `eks_s3.tf`와 관련 IRSA/애드온 블록을 활성화하고 `samples/s3-mount-test.yaml`로 곧바로 검증합니다.
2. **관측 스택 가동**: `helm_monitoring.tf`와 `manifests/alloy-configmap.hcl`을 기반으로 Prometheus/Grafana/Loki/Alloy를 재도입하고, HardenEKS 리포트와 연계합니다.
3. **서비스 메시 + 게이트웨이 보강**: `helm_istio_*.tf`와 WAF/ACM 템플릿을 활용해 Ambient/Sidecar 모드를 선택적으로 배포하고, Istio Ingress + ALB 조합을 정식화합니다.
4. **보안 도구 세트**: Trivy Operator, Falco, Cert-Manager, External-DNS, Kubecost 등을 단계적으로 재활성화해 운영/보안 체계를 강화합니다.

---

## 🔗 관련 링크

- [📖 메인 README](../README.md)
- [📖 Project 03 (Amazon Linux 2023)](../project03/README.md)
- [🔧 Bottlerocket 공식 문서](https://github.com/bottlerocket-os/bottlerocket)
- [🛡️ HardenEKS](https://github.com/aws-samples/harden-eks)
- [🕸️ Istio 문서](https://istio.io/latest/docs/)
- [📊 Grafana 대시보드](https://grafana.com/dashboards/)

---

## 🤝 기여 및 피드백

- 보안 취약점 · 성능 이슈 · 문서 개선 제안은 메인 저장소 이슈로 남겨 주세요.
- 주석 처리된 모듈을 활성화했을 때의 추가 요구사항이나 버그가 있다면 재현 방법과 함께 공유해 주세요.
