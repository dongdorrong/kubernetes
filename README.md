# Kubernetes & EKS Practice Suite

AWS EKS 학습·실험을 위한 Terraform/Helm/eksctl 예제 모음입니다. **Project 01~05**는 인프라를 Terrafrom/OpenTofu로 자동화하고, `eks_*`·`k3-kyverno-test` 디렉터리는 단일 목적 실습용 매니페스트를 제공합니다.

---

## Terraform/OpenTofu 프로젝트 한눈에 보기

| 프로젝트 | 쿠버네티스 버전 / OS | 핵심 주제 | 링크 |
| --- | --- | --- | --- |
| Project 01 | 1.2x / AL2 | VPC·노드 그룹·기본 리소스 실습, `architecture/` 다이어그램 + `resources/` 예제 모음 | [project01/README.md](./project01/README.md) |
| Project 02 | 1.2x / AL2 | ArgoCD·Helm·컨테이너 고급 구성·ALB Controller 실습(`practice/` 하위) | [project02/README.md](./project02/README.md) |
| Project 03 | 1.31 / Amazon Linux 2023 | Istio Ambient/Sidecar, Gateway API, Karpenter 1.4, ExternalDNS, Kubecost, Alloy 기반 관측 | [project03/README.md](./project03/README.md) |
| Project 04 | 1.33 / Bottlerocket | Bottlerocket+Karpenter, HardenEKS GitHub OIDC, 모니터링·보안 스택 템플릿, S3 CSI 샘플 | [project04/README.md](./project04/README.md) |
| Project 05 | 1.33 / Bottlerocket + Karpenter | **EKS Pod Identity 실험**: VPC CNI·EBS CSI·S3 CSI·ALB Controller 등 대부분 애드온을 Pod Identity로 전환, IRSA는 Karpenter만 유지 | [project05/README.md](./project05/README.md) |

모든 프로젝트는 `setAssumeRoleCredential.sh`를 포함하여 `terraform-assume-role` 또는 `eks-assume-role`을 선택하면 12시간짜리 STS 자격 증명을 `private` 프로파일에 주입합니다. `terraform/tfstate/` 폴더에 로컬 상태가 남아 있으므로 새 실습 전에 백업하거나 삭제한 뒤 `tofu init`/`terraform init`으로 재초기화하세요.

---

## eksctl & 단일 목적 실습

| 디렉터리 | 내용 |
| --- | --- |
| `eks_argocd/` | eksctl 기반 ArgoCD 예제 (GitOps) |
| `eks_elk/` | Elasticsearch/Kibana 클러스터 및 PVC/Ingress 매니페스트 |
| `eks_gp/` | Grafana/Prometheus 세트, PV·StorageClass 템플릿 포함 |
| `eks_istio/` | Istio 실험용 경량 EKS |
| `eks_jenkins/` | Jenkins CI/CD 배포 매니페스트 |
| `eks_github/`, `eks_gitlab/` | GitHub Actions Runner / GitLab CI 통합 실험 초안 |
| `k3-kyverno-test/` | Kyverno 정책 테스트 스크립트(`test-with-report.sh`)와 샘플 애플리케이션 |

---

## 공통 도구 & 자료

- `setAssumeRoleCredential.sh`: AWS CLI `private` 프로파일에 STS 세션 저장. `~/.aws/credentials_cleanAssumeRoleCredential` 백업을 참조하므로 최초 한 번은 수동 백업이 필요합니다.
- `project04/diagrams/`: Python 스크립트(`generate_all.py`)로 아키텍처 이미지를 다시 생성할 수 있습니다.
- 각 Terraform 프로젝트의 `manifests/`: Karpenter NodeClass/NodePool, Istio Gateway, StorageClass, Ingress 템플릿을 모아 둔 폴더입니다.

---

## 사전 요구사항

- AWS CLI v2, `kubectl`, `helm`, `jq`, (필요 시) `eksctl`
- Terraform 또는 OpenTofu 1.5 이상
- `AWS_PROFILE=private`, `AWS_REGION=ap-northeast-2` 기본 가정
- (선택) Python 3.10 이상 + `pip install -r project04/diagrams/requirements.txt` (다이어그램 재생성용)

---

## Terraform/OpenTofu 실행 절차

1. **자격 증명 준비**
   ```bash
   cp ~/.aws/credentials ~/.aws/credentials_cleanAssumeRoleCredential  # 최초 1회
   ./setAssumeRoleCredential.sh  # terraform 또는 eks 역할 선택
   aws sts get-caller-identity --profile private
   ```
2. **프로젝트별 변수 확인**  
   `terraform/locals.tf`에서 `project_name`, `owner(계정 ID)`, `admin_cidrs` 등을 환경에 맞게 조정합니다. 필요 시 `variables.tf`와 주석 처리된 `manifests/*.yaml`을 활성화하세요.
3. **상태 관리**  
   `terraform/tfstate/terraform.tfstate*`에 기존 실행 이력이 있으면 백업 후 삭제하거나 `tofu init -migrate-state`를 사용해 초기화합니다.
4. **배포**  
   ```bash
   cd terraform
   tofu init
   tofu plan
   tofu apply
   aws eks update-kubeconfig --name <cluster> --region ap-northeast-2 --profile private
   kubectl get nodes
   ```

---

## 학습 로드맵 제안

1. **기초 다지기**: Project 01 → Project 02 `practice/` 디렉터리.
2. **eksctl 실습**: `eks_argocd/`, `eks_jenkins/`, `k3-kyverno-test/`로 운영도구 흐름 익히기.
3. **프로덕션 아키텍처**: Project 03(관측/서비스 메시) → Project 04(보안·Bottlerocket).
4. **최신 기능 실험**: Project 05의 Pod Identity 애드온 구성. 필요 시 자체 브랜치에서 Karpenter Pod Identity 전환을 실험할 수 있도록 README에 가이드를 남겨 두었습니다.

---

## 메모

- 모든 Terraform 예제는 `ap-northeast-2` 리전을 기준으로 작성되었습니다. 다른 리전을 사용할 경우 VPC CIDR, ACM, Route53 설정을 함께 수정하세요.
- Pod Identity 실험(Project 05)은 VPC CNI/EBS CSI/ALB Controller 등 대부분 애드온을 Pod Identity로 전환했으며, Karpenter는 IRSA 주석과 OIDC 리소스를 그대로 유지합니다.
- `samples/` 디렉터리(예: `terraform/samples/ebs-static-pod.yaml`, `terraform/samples/alb-nlb-sample.yaml`)로 애드온 기능 검증을 자동화할 수 있습니다.
- 원격 Backend 대신 로컬 상태를 사용하므로 협업 시에는 `tfstate` 관리에 특히 주의하세요.

---

이 저장소는 개인 학습 및 실무 실험을 위한 자료입니다. 필요에 따라 자유롭게 수정·확장하세요.
