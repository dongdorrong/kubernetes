# 1) Argo CD Capability

EKS Capabilities의 Argo CD를 생성해 GitOps 기반 배포를 테스트합니다.
AWS Identity Center(SSO) 연동이 필수이며, Argo CD는 로컬 계정을 지원하지 않습니다.

## 기능 요약

- Git 리포지토리를 단일 소스로 삼아 클러스터 상태를 자동 동기화
- 수동 변경(드리프트) 감지 및 복구
- Argo CD 자체 운영/업그레이드를 AWS가 관리

## 사전 준비

- AWS Identity Center 인스턴스 ARN/사용자 ID 준비
- AWS CLI v2, kubectl 설치

IDC 정보 조회 예시:

```bash
# IDC 인스턴스 ARN
IDC_INSTANCE_ARN=$(aws sso-admin list-instances --region ap-northeast-2 --query 'Instances[0].InstanceArn' --output text)

# IDC 사용자 ID(사용자명은 본인 계정으로 변경)
IDC_USER_ID=$(aws identitystore list-users \
  --region ap-northeast-2 \
  --identity-store-id $(aws sso-admin list-instances --region ap-northeast-2 --query 'Instances[0].IdentityStoreId' --output text) \
  --query 'Users[?UserName==`your-username`].UserId' --output text)

echo "$IDC_INSTANCE_ARN"
echo "$IDC_USER_ID"
```

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project07/terraform/1-argocd
tofu init
tofu apply \
  -var cluster_name=ekscapabilities \
  -var region=ap-northeast-2 \
  -var profile=private \
  -var idc_instance_arn="$IDC_INSTANCE_ARN" \
  -var idc_region=ap-northeast-2 \
  -var idc_user_id="$IDC_USER_ID"
```

## 검증

```bash
aws eks describe-capability \
  --region ap-northeast-2 \
  --cluster-name ekscapabilities \
  --capability-name cap-argocd \
  --query 'capability.status' \
  --output text

kubectl api-resources | grep argoproj.io
```

`Application`, `ApplicationSet` 리소스가 보이면 정상입니다.

## 정리

```bash
tofu destroy
```

Capability 삭제 후에도 CRD/리소스는 남으므로 필요 시 별도 정리하세요.

## 참고(GitHub)

- https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/argocd-create-cli.adoc
