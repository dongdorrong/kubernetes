## 프로젝트 개요

이 리포지토리는 EKS 기반 인프라를 Terraform으로 구성하면서 **Istio Sidecar / Ambient Mesh + Gateway API** 조합을 검증하기 위한 실험장을 제공합니다. 목표는 다음과 같습니다.

- VPC, EKS, 추가 애드온(AWS LB Controller, Karpenter 등)을 Terraform으로 자동화
- Istio를 Sidecar 모드와 Ambient 모드로 각각 설치하고 Gateway API 리소스를 통한 L7 라우팅을 검증
- 동일한 네트워크 표준을 따르는 애플리케이션 Helm 차트를 정의하고 여러 값 파일로 다양한 샘플 앱을 배포

## 디렉터리 구조

- `terraform/`: 인프라 정의 루트. 주요 하위 항목
  - `*.tf`: EKS, 네트워크, IAM, Istio, Gateway API 등을 설치하는 Terraform 모듈
  - `manifests/`: Terraform에서 `kubectl_manifest`로 적용하는 고정 매니페스트
  - `charts/`: Istio Sidecar/Ambient 환경에서 사용할 Helm 차트 및 네트워킹 표준 문서(상세 내용은 `terraform/charts/README.md`)
- `setAssumeRoleCredential.sh`: Terraform 실행 시 사용할 AWS 자격 증명 설정 스크립트

## 진행 현황

- Sidecar 모드: `helm_istio_sidecar.tf`에서 Gateway API CRD, Istio base/istiod, Gateway 리소스를 설치
- Ambient 모드: 향후 `helm_istio_ambient.tf`를 활성화해 동일한 구조를 반영 예정
- 애플리케이션 차트: `terraform/charts/istio-sidecar-with-gatewayapi`, `terraform/charts/istio-ambient-with-gatewayapi`
  - nginx 기반 경량 웹서버
  - ConfigMap으로 index.html을 커스터마이징
  - Gateway API HTTPRoute를 기본 활성화

## 사용 방법 개요

1. `setAssumeRoleCredential.sh` 또는 원하는 방식으로 AWS 자격 증명을 구성합니다.
2. `terraform init && terraform apply`로 인프라를 배포합니다.
3. Istio/Gateway API 설치가 완료되면 `terraform/charts`에서 Helm 차트를 사용해 샘플 애플리케이션을 배포합니다.
4. Gateway API 경로는 `curl -H "Host: <hostname>" https://<LB 주소>` 형태로 검증할 수 있습니다.

자세한 네트워킹 표준과 차트 사용법은 `terraform/charts/README.md`를 참고하세요.
