# 2) ACK Capability

EKS Capabilities의 ACK(AWS Controllers for Kubernetes)를 생성해
Kubernetes CRD로 AWS 리소스를 제어하는 테스트를 진행합니다.

## 기능 요약

- Kubernetes CRD(spec/status)를 통해 AWS 리소스를 선언/동기화
- 컨트롤러가 지속적으로 desired state를 AWS에 반영
- 상태는 Kubernetes 리소스에 저장되어 별도 state 파일이 없음

## 이 폴더에서 하는 일

- ACK Capability IAM Role 생성
- 기본값으로 `AdministratorAccess` 정책을 연결(빠른 테스트용)
- ACK Capability 생성

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project07/terraform/2-ack
tofu init
tofu apply \
  -var cluster_name=ekscapabilities \
  -var region=ap-northeast-2 \
  -var profile=private
```

권한을 제한하고 싶으면 `policy_arns`를 바꿔주세요.

```bash
tofu apply -var 'policy_arns=["arn:aws:iam::aws:policy/AdministratorAccess"]'
```

## 검증

```bash
aws eks describe-capability \
  --region ap-northeast-2 \
  --cluster-name ekscapabilities \
  --capability-name cap-ack \
  --query 'capability.status' \
  --output text

kubectl api-resources | grep services.k8s.aws
```

## 예시 CRD

S3 버킷 생성 예시는 아래 파일을 참고하세요.

`/home/dongdorrong/github/private/kubernetes/project07/terraform/2-ack/examples/s3-bucket.yaml`

적용 전 버킷 이름을 전역 유니크하게 수정해야 합니다.

```bash
kubectl apply -f /home/dongdorrong/github/private/kubernetes/project07/terraform/2-ack/examples/s3-bucket.yaml
kubectl get bucket.s3.services.k8s.aws
```

삭제:

```bash
kubectl delete -f /home/dongdorrong/github/private/kubernetes/project07/terraform/2-ack/examples/s3-bucket.yaml
```

S3 리소스가 실제로 생성되므로 비용이 발생할 수 있습니다.

## 정리

```bash
tofu destroy
```

Capability 삭제 후에도 CRD/리소스는 남으므로 필요 시 별도 정리하세요.

## 참고(GitHub)

- https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/ack-create-cli.adoc
- https://github.com/aws-controllers-k8s/s3-controller
