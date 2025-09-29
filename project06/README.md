# Project 06 - HardenEKS & GitHub OIDC 실험 클러스터

> Project 05의 Pod Identity 구성을 확장해 GitHub Actions OIDC, HardenEKS 전용 접근 제어, Bottlerocket/AL2023 이중 Karpenter 노드 구성을 실험하는 테라폼 프로젝트입니다.

## 📋 프로젝트 개요

- **클러스터 이름**: `podidentity`
- **환경**: `dev`
- **리전**: `ap-northeast-2`
- **쿠버네티스 버전**: `1.33`
- **주요 목적**: Pod Identity 기반 애드온 운영 + HardenEKS 점검 도구 통합 + GitHub Actions OIDC 기반 접근 제어 검증

---

## 🔑 핵심 기능

### Pod Identity 확장
- `eks_addon.tf`에서 8종 관리형 애드온을 Pod Identity 기반으로 설치 (EBS CSI, ALB Controller, Network Flow Monitor, Node Monitoring, Snapshot Controller, Private CA Connector, Mountpoint S3 CSI, EFS CSI).
- `eks_addon_poi.tf`에서 각 애드온별 IAM 역할과 `aws_eks_pod_identity_association`을 정의하고, 공통 AssumeRole 정책을 `ArnLike` + `SourceAccount` 조건으로 제한.
- Mountpoint S3 CSI는 2025-09-28 기준 Pod Identity 토큰 버그가 있어 주석으로 보류된 상태 (`eks_addon.tf`, `eks_addon_poi.tf`).

### HardenEKS 통합
- `eks_hardeneks_iam.tf`에서 GitHub OIDC 공급자, HardenEKS 전용 IAM 역할/정책 (`manifests/hardeneks-policy.json`), EKS Access Entry를 생성.
- HardenEKS가 사용할 쿠버네티스 RBAC(`kubernetes_cluster_role`/`cluster_role_binding`)를 설정해 `hardeneks:runner` 그룹에 읽기 권한을 부여.
- `token.actions.githubusercontent.com:sub` 조건은 `repo:dongdorrong/hardeneks-test:ref:refs/heads/*`로 제한되어 있으므로 실사용 시 자신의 저장소/브랜치 패턴으로 수정해야 함.

### Karpenter & 노드 전략
- `manifests/karpenter-nodeclass-amazonlinux.yaml`, `manifests/karpenter-nodeclass-bottlerocket.yaml`를 포함해 Amazon Linux 2023과 Bottlerocket 노드 클래스를 모두 실험할 수 있도록 템플릿 제공.
- `eks_karpenter.tf`는 Project 05와 동일한 구성을 주석으로 유지하고 있어 필요 시 활성화해 Karpenter 1.4 배포 가능.

### 선택적 네트워킹 실험
- `helm_cilium.tf`에 Cilium 1.16 설치 템플릿을 주석으로 포함 (AWS CNI와 체이닝 모드로 공존 테스트용).

### 기타 구성 요소
- `eks_cluster.tf`는 Public/Private 동시 엔드포인트, `API_AND_CONFIG_MAP` 인증 모드를 사용하며, 관리형 노드 그룹은 Spot `t3.medium` 2대를 기본값으로 생성.
- `setAssumeRoleCredential.sh` 스크립트로 `terraform-assume-role`·`eks-assume-role` 중 선택하여 12시간 STS 세션을 발급.

---

## 📁 디렉터리 구조

```
project06/
├── README.md                     # 현재 문서
├── setAssumeRoleCredential.sh    # AWS STS AssumeRole 도우미 스크립트
└── terraform/
    ├── main.tf                   # Provider 버전 요구사항
    ├── locals.tf                 # project_name, VPC, CIDR, admin_cidrs 등 공용 변수
    ├── provider.tf               # AWS/Kubernetes/Helm/Kubectl Provider 설정
    ├── vpc.tf                    # VPC 및 서브넷, 게이트웨이 구성
    ├── eks_cluster.tf            # EKS 클러스터, 노드 그룹, aws-auth ConfigMap
    ├── eks_cluster_iam.tf        # 클러스터/노드 그룹 IAM 역할
    ├── eks_addon.tf              # 관리형 애드온 등록 및 Helm 기반 ALB Controller
    ├── eks_addon_poi.tf          # Pod Identity IAM 역할 및 Association
    ├── eks_hardeneks_iam.tf      # GitHub OIDC + HardenEKS IAM/RBAC 연동
    ├── eks_karpenter*.tf         # Karpenter 구성 (필요 시 주석 해제)
    ├── manifests/                # IAM 정책, Karpenter NodeClass/NodePool, Gateway 등 YAML/HCL 자산
    └── tfstate/                  # 로컬 Terraform 상태 파일 (실습 전 초기화 권장)
```

---

## 🚀 배포 절차

1. **자격 증명 준비**
   - `~/.aws/credentials_cleanAssumeRoleCredential` 파일이 존재하는지 확인하고 없으면 기존 자격 증명을 복제합니다.
   - `./setAssumeRoleCredential.sh` 실행 후 `terraform-assume-role` 또는 `eks-assume-role`을 선택해 STS 세션을 발급합니다.

2. **환경 변수 조정**
   - `terraform/locals.tf`에서 `project_name`, `owner`, `admin_cidrs`를 환경에 맞게 수정합니다.
   - HardenEKS를 실제 GitHub 저장소에서 사용하려면 `eks_hardeneks_iam.tf`의 `token.actions.githubusercontent.com:sub` 조건을 자신의 리포지터리 패턴으로 교체합니다.

3. **Terraform 실행**
   - 필요 시 `terraform/tfstate/terraform.tfstate*` 파일을 제거하거나 백업합니다.
   - `terraform` 디렉터리에서 `terraform init`, `terraform plan`, `terraform apply`를 순차 실행합니다.

4. **클러스터 접근**
   - `aws eks update-kubeconfig --name podidentity --region ap-northeast-2 --profile private` 실행으로 kubeconfig를 갱신합니다.
   - `kubectl get nodes`, `kubectl get pods -n kube-system`으로 애드온과 노드 상태를 확인합니다.

5. **HardenEKS 검증 (선택)**
   - GitHub Actions 워크플로에서 HardenEKS 스캐너를 실행하면 Access Entry/RBAC 설정을 통해 클러스터 정보를 읽을 수 있어야 합니다.
   - 권한 부족 오류가 발생하면 IAM 정책(`manifests/hardeneks-policy.json`)과 RBAC 권한을 추가 조정합니다.

---

## ✅ 체크리스트

- Pod Identity 애드온이 모두 `ACTIVE` 상태인지 (`aws eks list-addons` 또는 `kubectl get pods -n kube-system`) 확인.
- HardenEKS 역할이 `aws eks list-access-entries --name podidentity` 결과에 포함되어 있는지 검증.
- 필요 시 주석 처리된 Karpenter/Cilium/Mountpoint S3 구성을 해제하고 `terraform apply`로 재배포.

---

## 🔮 향후 과제

- Mountpoint S3 CSI의 Pod Identity 토큰 이슈 해결 후 주석 해제 및 통합 테스트.
- Cilium 체이닝 모드 검증 및 관련 네트워크 정책 예제 추가.
- HardenEKS 워크플로 샘플(GitHub Actions) 제공으로 엔드투엔드 점검 자동화.
- Bottlerocket Karpenter NodeClass를 활성화하여 실운영 환경에서의 조합 검증.

---

이 문서는 2025-09-29 기준 저장소 상태를 반영합니다.
