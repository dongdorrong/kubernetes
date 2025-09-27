# project05 - EKS Pod Identity 기반 애드온 구성

## 배경
- project04까지는 IRSA(IAM Roles for Service Accounts) 기반으로 애드온 및 컨트롤러에 IAM 권한을 부여했습니다.
- project05에서는 Amazon EKS Pod Identity를 도입하여 애드온이 `pods.eks.amazonaws.com` 서비스 프린시펄을 통해 STS 세션을 요청하도록 개선했습니다.
- Pod Identity 에이전트 애드온을 기본으로 설치하고, 필요 권한은 Terraform에서 Pod Identity Association과 IAM 역할로 관리합니다.

## 핵심 변경 사항
- `eks_addon.tf`
  - `eks-pod-identity-agent`를 기준으로 하여 CoreDNS, VPC CNI, EBS CSI 등 기존 애드온 구성을 유지하면서 추가 애드온을 Pod Identity 기반으로 설치.
  - 새로 요구된 애드온 6종을 관리형 애드온으로 선언:
    - AWS Network Flow Monitor Agent
    - EKS Node Monitoring Agent
    - CSI Snapshot Controller
    - AWS Private CA Connector for Kubernetes
    - Mountpoint for Amazon S3 CSI Driver
    - Amazon EFS CSI Driver
- `eks_addon_poi.tf`
  - Pod Identity 공유 AssumeRole 정책을 확장하고, 각 애드온별 IAM 역할·정책·Pod Identity Association을 정의.
  - 정책 JSON은 `terraform/manifests/*.json`으로 분리하여 Terraform 코드 가독성을 확보.
- `terraform/manifests`
  - 네트워크 플로우 모니터, 노드 모니터링, Private CA 커넥터, Mountpoint S3 CSI용 정책 문서를 추가.

## 구성 요소 요약
- Pod Identity 기반으로 애드온이 필요한 권한을 획득하므로 OIDC 프로바이더 없이도 STS 세션을 발급할 수 있습니다.
- 각 애드온의 서비스 어카운트는 AWS 기본 네이밍을 따르며, Terraform `depends_on`으로 설치 순서를 명시했습니다.
- 정책 문서는 현재 전체 리소스(`*`)에 대한 권한을 허용하며, 운영 환경에 맞춰 리소스 범위를 좁히는 것을 권장합니다.

## 배포 절차
1. `terraform/` 디렉터리에서 `terraform init` 실행.
2. 변경 사항 검토를 위해 `terraform plan` 수행.
3. 승인 후 `terraform apply`로 애드온 및 IAM 구성을 배포.

## 향후 고려 사항
- Mountpoint for Amazon S3 CSI 및 EFS CSI는 실제 스토리지 리소스와 연동할 때 버킷/파일시스템 ARN 기반으로 정책을 세분화해야 합니다.
- Private CA Connector는 발급 대상 CA 및 네임스페이스 정책을 추가로 정의하면 보안 강화를 기대할 수 있습니다.
