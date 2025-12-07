# 프로젝트 개요
- `project05/terraform` 폴더는 EKS 1.33 클러스터와 필수 인프라(VPC, KMS, S3, ACM 등)를 OpenTofu(Terraform)로 구성한다.
- 인증은 `API_AND_CONFIG_MAP` 모드로 설정하고, `aws-auth` ConfigMap을 Terraform에서 관리하여 기본 노드 그룹과 Karpenter 노드 역할을 매핑한다.
- 새로운 애드온(VPC CNI, EBS CSI, S3 CSI, AWS Load Balancer Controller)은 **EKS Pod Identity**를 기본값으로 사용한다.
- Karpenter 컨트롤러는 아직 IRSA 방식을 유지하지만, 노드 풀 및 NodeClass는 manifests 폴더의 템플릿을 통해 자동 배포된다.

# 구성 파일 구조
| 경로 | 설명 |
| --- | --- |
| `terraform/main.tf` | backend/state, 공통 provider 로딩 |
| `terraform/vpc.tf` | VPC, 서브넷, NAT 게이트웨이, 라우팅 |
| `terraform/eks_cluster*.tf` | EKS 클러스터, IAM, access entry, aws-auth ConfigMap |
| `terraform/eks_addon*.tf` | Pod Identity 기반 애드온 및 IAM 역할 정의 |
| `terraform/eks_karpenter*.tf` | Karpenter Helm 설치, NodePool/NodeClass, KMS |
| `terraform/manifests/*` | NodeClass, NodePool, StorageClass 등 Kubernetes 매니페스트 |
| `terraform/samples/*` | 기능 점검용 YAML (EBS PVC, ALB/NLB 테스트 등) |
| `setAssumeRoleCredential.sh` | `terraform-assume-role` 또는 `eks-assume-role`을 사용하는 STS 셸 스크립트 |

# 사전 준비
1. **필수 도구**
   - OpenTofu ≥ 1.7 (또는 Terraform 동등 버전)
   - AWS CLI v2, `jq`
   - `kubectl`, `helm`, `kubectl-neat`(선택)
2. **AWS 프로필**
   - `~/.aws/credentials_cleanAssumeRoleCredential` 백업 파일이 있어야 `setAssumeRoleCredential.sh`를 통해 `private` 프로필을 덮어쓸 수 있다.
3. **환경 변수**
   - `AWS_PROFILE=private`
   - `AWS_REGION=ap-northeast-2`

# 배포 절차
1. **역할 전환**
   ```bash
   cd /home/dongdorrong/github/private/kubernetes/project05
   ./setAssumeRoleCredential.sh   # terraform-assume-role 또는 eks-assume-role 선택
   aws sts get-caller-identity --profile private
   ```
2. **Terraform 실행**
   ```bash
   cd terraform
   tofu init
   tofu plan
   tofu apply
   ```
3. **kubeconfig 갱신 & 확인**
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region ap-northeast-2 --profile private
   kubectl get nodes
   ```

# 배포 후 검증
1. **Pod Identity 연결 상태**
   ```bash
   aws eks list-pod-identity-associations \
     --cluster-name <cluster-name> \
     --region ap-northeast-2 \
     --profile private
   ```
2. **EBS PVC 테스트 (`samples/ebs-static-pod.yaml`)**
   ```bash
   kubectl apply -f terraform/samples/ebs-static-pod.yaml
   kubectl logs -f ebs-static-pod
   kubectl delete -f terraform/samples/ebs-static-pod.yaml
   ```
3. **ALB/NLB 테스트 (`samples/alb-nlb-sample.yaml`)**
   ```bash
   kubectl apply -f terraform/samples/alb-nlb-sample.yaml
   kubectl get ingress -n lb-test
   kubectl get svc nlb-demo -n lb-test
   kubectl delete -f terraform/samples/alb-nlb-sample.yaml
   ```

# 운영 메모
- **Karpenter IRSA**: 현재 IRSA를 유지하고 있으므로 `aws_iam_openid_connect_provider` 리소스를 삭제하면 안 된다. 추후 Pod Identity로 전환하려면 ServiceAccount와 `aws_eks_pod_identity_association`을 별도로 추가해야 한다.
- **State 관리**: `terraform/tfstate/` 디렉터리가 존재하므로 원격 backend 설정(필요 시)으로 migration 할 수 있다.
- **클린업**
  ```bash
  cd terraform
  tofu destroy
  aws s3 rm s3://<app-data-bucket> --recursive   # 필요 시
  ```

# 참고 링크
- [EKS Pod Identity 공식 문서](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [Karpenter 설치 가이드](https://karpenter.sh/docs/getting-started/)
- [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)
