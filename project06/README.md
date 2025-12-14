# project06: project04 포크 + 모듈 기반 PoC 무대

`project06`는 `/home/dongdorrong/github/private/kubernetes/project04`를 복제한 뒤, **리소스를 덩어리별로 켰다 껐다 할 수 있는 모듈 구조**로 재편한 실험 저장소입니다. project04에서 여러 `.tf` 파일을 부분 주석 처리하며 PoC하던 방식을 완전히 걷어내고, “기본 인프라 → EKS → EKS 애드온 → 수동/Helm 배포” 순서를 명시적으로 나눠 다시 설계했습니다.

## 변환 배경

| 구분 | project04 | project06 |
| --- | --- | --- |
| 코드 배치 | 단일 루트에 모든 리소스를 정의, 필요 시 파일 안에서 주석 처리 | 단계별 `*.tf` + `modules/*` 구조. 각 단계는 독립적으로 apply 가능 |
| 수동 작업 | Gateway, Helm 샘플 등을 직접 `kubectl`/`helm`으로 배포 | Terraform 출력으로 명령어를 안내하거나, Helm 릴리스를 모듈에서 토글 |
| 재사용성 | 파일마다 상호 참조가 복잡해 다른 실험에 재사용이 어려움 | `modules/network`, `modules/eks_default` 등으로 나눠 향후 project07+에서도 재사용 가능 |

## 디렉터리 & 단계 요약

```text
project06/
├─ README.md                  # (이 파일) 모듈화 히스토리와 실행 가이드
├─ setAssumeRoleCredential.sh # AWS AssumeRole 환경 변수 설정 스크립트
└─ terraform/
   ├─ 1-basic.tf              # 네트워크·ACM·AssumeRole 데이터 소스
   ├─ 1-basic-outputs.tf      # 1단계 출력
   ├─ 2-eks_default.tf        # (기본값: 주석) EKS 클러스터 모듈
   ├─ 2-eks_default-outputs.tf
   ├─ 3-eks_addons.tf         # (기본값: 주석) EKS 애드온 + Karpenter 등
   ├─ 3-eks_addons-outputs.tf
   ├─ 4-yaml_manual_apply.tf  # (기본값: 주석) 수동 kubectl apply 목록
   ├─ manifests/              # gateway, karpenter, storageclass 등 고정 YAML
   └─ modules/                # 재사용 모듈 모음
      ├─ network              # VPC, 서브넷, NAT, 라우팅
      ├─ acm                  # 기존 인증서 조회
      ├─ iam_assume_roles     # Terraform/EKS AssumeRole 데이터
      ├─ eks_default          # EKS + 노드 그룹 + Access Entry
      ├─ eks_addons           # ALB Controller / Addons / Karpenter / IRSA
      └─ helm_apps            # 로컬/원격 Helm 릴리스 토글 엔진
```

### 단계별 apply 전략

1. **기본 인프라 (`1-basic.tf`)**
   - `network`, `acm`, `iam_assume_roles` 모듈만 활성화되어 있습니다.
   - `terraform/1-basic-outputs.tf`에서 VPC/Subnet/ACM/AssumeRole 정보를 확인할 수 있습니다.
2. **EKS 클러스터 (`2-eks_default.tf`)**
   - 필요할 때 `module "eks_default"` 블록의 주석을 해제하고 apply합니다.
   - `2-eks_default-outputs.tf`의 주석도 함께 풀면 클러스터 정보 출력이 재활성화됩니다.
3. **EKS 애드온 (`3-eks_addons.tf`)**
   - `eks_default` 모듈을 배포한 뒤 주석을 해제합니다.
   - AWS Load Balancer Controller, VPC CNI/EB SCSI IRSA, Karpenter Helm 릴리스까지 몽땅 한 번에 깔립니다.
4. **수동/Helm 배포**
   - `manifests/` 폴더는 Terraform 모듈에서 참조하거나, `4-yaml_manual_apply.tf`의 리스트에 파일명을 넣어 `apply` 시 “이 파일을 kubectl로 적용하세요”라는 명령어 출력을 받을 수 있습니다.
   - `modules/helm_apps`는 로컬 차트(`modules/helm_apps/charts/...`)와 원격 레포를 동시에 지원합니다. 현재 루트에는 토글 변수 파일(예: `5-helm_deploy.tf`)을 두지 않았으니, 특정 환경에 맞춰 별도 tf 파일을 만들어 `module "helm_apps"`를 호출하면 됩니다.

> ✅ **핵심 아이디어**  
> 필요한 단계의 파일만 주석 해제하고 `tofu plan/apply`를 실행하면, 이전 단계의 상태에는 영향을 주지 않고 실험을 이어갈 수 있습니다.

## 실행 순서 예시

```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform
./../setAssumeRoleCredential.sh   # 또는 원하는 자격 증명 설정
tofu init                         # 네트워크 제한 환경이라면 미리 provider 플러그인 캐시 필요
tofu apply -target=module.network # VPC만 먼저 만들고 싶을 때

# EKS를 만들 준비가 되면
vim 2-eks_default.tf              # module 블록 주석 해제
tofu apply -parallelism=20

# 애드온까지 배포할 준비가 되면
vim 3-eks_addons.tf               # module 블록 주석 해제
tofu apply
```

## Helm & manifests 연동

- **Helm**: `modules/helm_apps/main.tf`는 `applications` 맵에 `enabled=true`인 엔트리만 `helm_release`로 만듭니다. 값 파일 경로는 절대 경로를 사용하므로 `${path.root}/modules/helm_apps/charts/...` 형태를 그대로 입력하세요.
- **manifests**: Gateway, Karpenter, StorageClass, S3 CSI 정책 등 project04에서 쓰던 YAML을 모두 `terraform/manifests/`로 옮겨, 모듈(`eks_addons`)과 `4-yaml_manual_apply.tf` 양쪽에서 참조합니다. project04에서 누락되던 파일(예: `storageclass.yaml`)을 다시 포함했는지 이 폴더를 보면 즉시 확인할 수 있습니다.

## 앞으로의 확장 포인트

1. **Helm 토글 파일(예: `5-helm_deploy.tf`)**을 새로 만들어 `module "helm_apps"`에 `applications` 맵을 넘기면, Istio 샘플/ambient chart/Prometheus 등 커뮤니티 차트를 손쉽게 배포할 수 있습니다.
2. project04에서 사용하던 나머지 tf 파일을 가져오고 싶다면, 동일한 규칙(각 번호별 `.tf` + `-outputs.tf`)을 유지하면서 모듈에 추가 인자를 공급하는 방식으로 정리하면 됩니다.
3. 운영/테스트 계정에 따라 `locals` 값만 바꿔도 동일한 모듈 묶음을 재사용할 수 있도록, `variables.tf` 확장을 고려하면 좋습니다.

이 README는 project04를 project06으로 모듈화하면서 생긴 모든 결정과 디렉터리 레이아웃을 문서화하여 “어떤 파일을 열어야 어떤 리소스를 제어할 수 있는지”를 명확히 보여주기 위해 작성되었습니다. 필요한 단계가 생기면 해당 번호의 `.tf`/`-outputs.tf`만 주석 해제하고 apply하는 워크플로를 따르면 됩니다.
