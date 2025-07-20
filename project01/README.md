# Project 01 - 기본 EKS 클러스터 구성

> EKS 클러스터 기본 구성과 아키텍처 학습을 위한 기초 프로젝트

## 📋 프로젝트 개요

- **목적**: EKS 클러스터 구축의 기본 개념과 구성 요소 학습
- **대상**: 쿠버네티스 초보자
- **범위**: EKS 기본 구성, VPC 네트워킹, 기본 애드온

---

## 📁 프로젝트 구조

```
project01/
├── architecture/         # 프로젝트 아키텍처 다이어그램
│   ├── *.drawio          # Draw.io 아키텍처 파일
│   └── *.png             # 아키텍처 이미지 파일
└── resources/            # 기본 쿠버네티스 리소스
    ├── container/        # 컨테이너 기본 구성
    ├── helm/             # 헬름 차트 기본 예제
    ├── storage/          # 스토리지 구성
    └── terraform/        # 테라폼 기본 구성
```

---

## 🎯 학습 목표

### 🏗️ **인프라 기초**
- AWS VPC 네트워킹 이해
- EKS 클러스터 기본 구성
- 노드 그룹 설정
- 보안 그룹 구성

### 🔧 **쿠버네티스 기초**
- 기본 오브젝트 이해 (Pod, Service, Deployment)
- 네임스페이스 관리
- ConfigMap, Secret 사용법
- 기본 스토리지 개념

### ⚙️ **도구 활용**
- kubectl 기본 명령어
- Terraform 기초 사용법
- Helm 차트 기본 개념
- AWS CLI 활용

---

## 🚀 시작하기

### 사전 요구사항
- AWS CLI 설치 및 설정
- Terraform 설치
- kubectl 설치
- 기본 AWS 권한 설정

### 학습 순서

#### 1. 아키텍처 이해
```bash
# 아키텍처 다이어그램 확인
cd architecture/
# .drawio 파일을 Draw.io에서 열어서 구조 확인
# .png 파일로 전체 아키텍처 확인
```

#### 2. 기본 리소스 실습
```bash
cd resources/

# 컨테이너 기본 실습
cd container/
kubectl apply -f basic-pod.yaml
kubectl apply -f basic-deployment.yaml

# 헬름 차트 기본 실습  
cd ../helm/
helm install my-app ./basic-chart

# 스토리지 실습
cd ../storage/
kubectl apply -f persistent-volume.yaml
kubectl apply -f persistent-volume-claim.yaml

# 테라폼 기본 실습
cd ../terraform/
terraform init
terraform plan
terraform apply
```

---

## 📚 학습 리소스

### 핵심 개념
1. **VPC & 네트워킹**
   - Public/Private 서브넷 구분
   - NAT Gateway 역할
   - 보안 그룹 vs NACL

2. **EKS 기본사항**
   - 컨트롤 플레인 vs 데이터 플레인
   - 노드 그룹 타입 (관리형/자체 관리형)
   - IAM 역할 및 정책

3. **쿠버네티스 오브젝트**
   - Pod 생명주기
   - Service 타입 (ClusterIP, NodePort, LoadBalancer)
   - Deployment vs ReplicaSet

---

## 🔍 실습 예제

### 기본 파드 배포
```yaml
# basic-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

### 서비스 노출
```yaml
# basic-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

### 배포 명령어
```bash
# 파드 배포
kubectl apply -f basic-pod.yaml

# 서비스 배포
kubectl apply -f basic-service.yaml

# 상태 확인
kubectl get pods
kubectl get services
kubectl describe pod nginx-pod

# 로그 확인
kubectl logs nginx-pod

# 파드 삭제
kubectl delete -f basic-pod.yaml
kubectl delete -f basic-service.yaml
```

---

## 🔧 트러블슈팅

### 일반적인 문제

#### 파드가 Pending 상태
```bash
# 노드 상태 확인
kubectl get nodes

# 이벤트 확인
kubectl describe pod <pod-name>

# 리소스 확인
kubectl top nodes
```

#### 서비스 접근 불가
```bash
# 서비스 상태 확인
kubectl get svc
kubectl describe svc <service-name>

# 엔드포인트 확인
kubectl get endpoints

# 보안 그룹 확인 (AWS 콘솔)
```

---

## 📖 다음 단계

Project 01 완료 후 추천 학습 경로:

1. **[Project 02](../project02/README.md)**: 쿠버네티스 실습 환경
   - ArgoCD로 GitOps 체험
   - Helm 차트 고급 활용
   - AWS Load Balancer Controller

2. **[EKS 전용 구성](../eks_argocd/README.md)**: DevOps 도구 체험
   - Jenkins CI/CD
   - Istio 서비스 메시
   - 모니터링 스택

3. **[Project 03](../project03/README.md)**: 프로덕션 환경 도전
   - 실제 운영 환경 구성
   - 고급 스케일링
   - 완전한 관측성

---

## 🔗 관련 링크

- [📖 메인 README](../README.md)
- [📖 Project 02 (실습 환경)](../project02/README.md)
- [🔧 AWS EKS 문서](https://docs.aws.amazon.com/eks/)
- [🔧 Kubernetes 문서](https://kubernetes.io/docs/)
- [🔧 Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🤝 기여 및 피드백

초보자 관점에서의 피드백을 환영합니다:
- 이해하기 어려운 부분
- 추가 설명이 필요한 개념
- 실습 예제 개선사항
- 문서 개선 제안 