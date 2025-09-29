# Kubernetes & EKS Practice Suite

> AWS EKS를 학습하고 실무형 클러스터를 반복 구축하기 위한 Terraform·Helm·eksctl 예제 모음입니다.

## Terraform 기반 프로젝트

- **Project 01 – 기본 EKS 클러스터 입문**  
  VPC 네트워킹과 관리형 노드 그룹 구성, 기본 쿠버네티스 오브젝트 실습을 다룹니다. `architecture/`에는 Draw.io 다이어그램이, `resources/`에는 컨테이너·Helm·스토리지·Terraform 예제가 정리되어 있습니다.  
  → [project01/README.md](./project01/README.md)

- **Project 02 – 쿠버네티스 실습 환경**  
  ArgoCD, Helm, 컨테이너 고급 구성, AWS Load Balancer Controller 실습을 위한 중급 프로젝트입니다. 모든 실습은 `practice/` 하위 디렉터리( `argocd/`, `helm/`, `container/`, `setup_alb_controller/`, `terraform/`)에 배치되어 있습니다.  
  → [project02/README.md](./project02/README.md)

- **Project 03 – 프로덕션급 EKS (Amazon Linux 2023, Kubernetes 1.31)**  
  Istio Ambient & Sidecar Mesh, Gateway API, Karpenter v1.4, Prometheus/Grafana/Loki/Alloy, ExternalDNS, Kubecost 등 운영 필수 스택을 Terraform으로 구성합니다. `manifests/` 폴더에는 Karpenter NodeClass·NodePool, Istio Gateway, Add-on Ingress 등이 포함됩니다.  
  → [project03/README.md](./project03/README.md)

- **Project 04 – Bottlerocket 기반 보안 강화 EKS (Kubernetes 1.33)**  
  Bottlerocket 노드, Keycloak SSO, Trivy Operator, Istio Ambient/Sidecar Mesh, AWS WAF, 완전한 모니터링 스택을 다룹니다. `diagrams/` 폴더의 Python 스크립트를 이용해 아키텍처 이미지를 재생성할 수 있습니다.  
  → [project04/README.md](./project04/README.md)

- **Project 05 – EKS Pod Identity 기반 애드온 운영 (Kubernetes 1.33)**  
  eks-pod-identity-agent를 기반으로 ALB Controller, Network Flow Monitor, Node Monitoring, Private CA Connector, Snapshot Controller, Mountpoint for S3 CSI, EFS CSI 등 8종 애드온을 Pod Identity로 권한 위임합니다. Karpenter 1.4, gp3 StorageClass, Helm 기반 ALB Controller, IAM 정책 JSON이 포함됩니다.  
  → [project05/README.md](./project05/README.md)

- **Project 06 – Pod Identity + HardenEKS 통합 실험 (Kubernetes 1.33)**  
  Project 05 구성을 확장해 GitHub OIDC(OpenID Connect) 공급자와 HardenEKS 전용 Access Entry/RBAC을 추가합니다. Bottlerocket·Amazon Linux 이중 Karpenter NodeClass, Mountpoint S3 CSI, Cilium 설치 등은 Terraform 주석으로 제공되어 있어 필요 시 활성화하여 실험할 수 있습니다. 현재 [project06/README.md](./project06/README.md)는 Project 05의 임시 사본이며 실제 변경 사항은 `terraform/` 디렉터리 주석을 참고하세요.

공통으로 Project 03~06에는 `setAssumeRoleCredential.sh` 스크립트가 포함되어 `terraform-assume-role`과 `eks-assume-role` 중 하나를 선택해 12시간 STS 세션을 발급합니다. 각 프로젝트의 `terraform/tfstate/`에는 과거 실행 이력이 남아 있으므로 새로 실습할 때는 상태 파일을 백업하거나 삭제하고 초기화하세요.

## eksctl 및 개별 매니페스트 예제

| 디렉터리 | 용도 | 주요 파일 | 상태 |
|----------|------|-----------|------|
| `eks_argocd/` | eksctl로 ArgoCD 실습용 EKS 클러스터 생성 | `cluster.yml` | 샘플 완료 |
| `eks_istio/` | eksctl 기반 Istio 테스트 클러스터 | `cluster.yml` | 샘플 완료 |
| `eks_jenkins/` | Jenkins CI/CD 클러스터 및 배포 매니페스트 | `cluster.yml`, `deploy.yml`, `sa.yml`, `svc.yml`, `pvc.yml` | 샘플 완료 |
| `eks_elk/` | Elasticsearch/Kibana용 리소스 세트 | `cluster.yml`, `es.yml`, `kb.yml`, `pv*.yml`, `stc.yml`, `ingress.yml` | 샘플 완료 |
| `eks_gp/` | Grafana/Prometheus 관측 스택 | `cluster.yml`, `values-grafana.yaml`, `values-prometheus.yaml`, `pv-*.yml`, `stc.yml` | 샘플 완료 |
| `eks_github/` | GitHub Actions 셀프 호스트 러너 실험 | `cluster.yml`, `Dockerfile` | 진행 중 (구성 초안) |
| `eks_gitlab/` | GitLab CI 통합 실험 | `cluster.yml`, `get_helm.sh`, `es.yml`, `pv-*.yml`, `ingress.yml`, `stc.yml` | 진행 중 (구성 초안) |

## 정책·테스트 자산

- `k3-kyverno-test/`
  - `dummy-app/`과 `kyverno-policy/kyverno-policies.yaml`로 Kyverno 정책을 검증합니다.
  - `kyverno/` 디렉터리는 Kyverno Helm 차트(버전 3.4.1) 문서를 포함합니다.
  - `test-with-report.sh` 스크립트는 k3s 환경에서 정책 테스트를 수행하고 타임스탬프 기반 Markdown 리포트를 생성합니다 (`kyverno-test-report-*.md`).

## 공용 자료

- `project01/architecture/`: 기본 아키텍처 Draw.io 파일과 PNG 이미지.
- `project04/diagrams/`: `generate_all.py`와 `requirements.txt`로 보안/모니터링/Istio 아키텍처 이미지를 자동 생성.
- Terraform 프로젝트의 `manifests/` 폴더: Istio Gateway, Gateway API, StorageClass, Ingress 등 쿠버네티스 YAML을 모아둔 디렉터리.

## 사전 요구사항

- `awscli`가 설치되어 있고 `private` 프로파일이 구성되어 있어야 합니다. 프로젝트 스크립트는 `~/.aws/credentials_cleanAssumeRoleCredential` 백업 파일을 참조합니다.
- Terraform 1.2 이상 (1.5 이상 권장).
- `kubectl`, `helm`, `eksctl`, `jq`.
- (선택) 다이어그램 생성을 위한 Python 3.10 이상과 `pip install -r project04/diagrams/requirements.txt`.

## Terraform 실행 공통 절차

1. `~/.aws/credentials_cleanAssumeRoleCredential` 파일이 없는 경우 기존 자격 증명을 백업해 만듭니다.  
   `cp ~/.aws/credentials ~/.aws/credentials_cleanAssumeRoleCredential`
2. 프로젝트 루트에서 `./setAssumeRoleCredential.sh`를 실행해 `terraform-assume-role` 또는 `eks-assume-role`을 선택합니다. 세션은 12시간 유지됩니다.
3. `terraform/locals.tf`에서 `project_name`, `owner`(계정 ID), `admin_cidrs` 등을 자신의 환경에 맞게 수정합니다.
4. 필요 시 `variables.tf`와 `manifests/`의 주석 처리된 리소스를 활성화해 실험 범위를 조정합니다 (예: Project 06의 Cilium, Mountpoint S3 CSI, Karpenter NodeClass).
5. 기존 상태를 사용하지 않으려면 `terraform/tfstate/terraform.tfstate*` 파일을 제거하거나 별도 백업 후 `terraform init -migrate-state`로 초기화합니다.
6. `terraform init`, `terraform plan`, `terraform apply`를 수행합니다.
7. 배포 후 `aws eks update-kubeconfig --name <클러스터 이름> --profile private` 명령으로 kubeconfig를 갱신하고 `kubectl get nodes`로 상태를 확인합니다.
8. Project 06을 사용할 경우 `eks_hardeneks_iam.tf`의 GitHub `token.actions.githubusercontent.com:sub` 조건을 자신의 리포지토리/브랜치 패턴에 맞게 수정해야 HardenEKS 롤이 동작합니다.

## 학습 로드맵

1. **초급**: Project 01 → Project 02의 `practice/` 실습으로 기본기를 다집니다.
2. **중급**: `eks_argocd/`, `eks_jenkins/` 등 eksctl 샘플과 `k3-kyverno-test/` 정책 검증을 통해 운영 도구 흐름을 익힙니다.
3. **고급**: Project 03과 Project 04로 프로덕션 수준 스택을 경험합니다.
4. **최신 기능·보안 실험**: Project 05와 Project 06에서 EKS Pod Identity, HardenEKS, GitHub OIDC 통합을 검증합니다.

## 메모

- Terraform 예제 대부분이 `ap-northeast-2` 리전을 전제로 하므로 다른 리전을 사용할 경우 `locals.tf`와 ACM/Route53 설정을 함께 조정해야 합니다.
- S3 버킷, Mountpoint S3 CSI, Cilium 등 일부 리소스는 주석 처리되어 있으며 실험 시 활성화 후 필요한 IAM 정책과 네임스페이스를 검토하세요.
- 원격 상태 백엔드 대신 로컬 상태를 사용하고 있으므로 실습 전후로 상태 파일 관리에 주의하세요.

## 라이선스

이 저장소는 개인 학습과 실무 실험을 위해 제작되었습니다. 필요에 맞게 수정하여 사용하세요.
