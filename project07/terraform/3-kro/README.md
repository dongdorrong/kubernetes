# 3) kro Capability

EKS Capabilities의 kro(Kube Resource Orchestrator)를 생성해
ResourceGraphDefinition 기반 오케스트레이션을 테스트합니다.

## 기능 요약

- 여러 리소스를 조합한 상위 API(ResourceGraphDefinition) 정의
- 표준 패턴을 템플릿으로 제공해 self-service 형태로 사용
- 필요한 경우 ACK 리소스까지 묶어 하나의 추상 리소스로 구성

## 이 폴더에서 하는 일

- kro Capability IAM Role 생성
- kro Capability 생성
- (옵션) `AmazonEKSClusterAdminPolicy` 연결로 리소스 생성 권한 부여

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project07/terraform/3-kro
tofu init
tofu apply \
  -var cluster_name=ekscapabilities \
  -var region=ap-northeast-2 \
  -var profile=private
```

권한 연결을 끄고 싶으면:

```bash
tofu apply -var associate_cluster_admin_policy=false
```

## 검증

```bash
aws eks describe-capability \
  --region ap-northeast-2 \
  --cluster-name ekscapabilities \
  --capability-name cap-kro \
  --query 'capability.status' \
  --output text

kubectl api-resources | grep kro.run
```

`ResourceGraphDefinition` 리소스가 보이면 정상입니다.

## 정리

```bash
tofu destroy
```

Capability 삭제 후에도 CRD/리소스는 남으므로 필요 시 별도 정리하세요.

## 참고(GitHub)

- https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/kro-create-cli.adoc
