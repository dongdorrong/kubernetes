# Project 02 - 쿠버네티스 실습 환경

> 쿠버네티스 오브젝트 및 도구 실습을 위한 중급 프로젝트

## 📋 프로젝트 개요

- **목적**: 실무에서 자주 사용하는 쿠버네티스 도구들의 실전 활용법 학습
- **대상**: 쿠버네티스 기본 개념을 이해한 중급자
- **범위**: ArgoCD, Helm, ALB Controller, Container 고급 구성

---

## 📁 프로젝트 구조

```
project02/
└── practice/             # 실습 디렉토리
    ├── argocd/          # GitOps 배포 자동화 실습
    ├── container/       # 컨테이너 고급 구성
    ├── helm/            # 헬름 차트 실습
    ├── setup_alb_controller/  # AWS Load Balancer Controller 설정
    └── terraform/       # 테라폼 고급 실습
```

---

## 🎯 학습 목표

### 🚀 **GitOps 워크플로우**
- ArgoCD 설치 및 구성
- Git 기반 배포 자동화
- 애플리케이션 동기화
- 롤백 및 히스토리 관리

### ⚡ **AWS 네이티브 통합**
- AWS Load Balancer Controller 구성
- ALB Ingress 설정
- Target Group 자동 관리
- SSL/TLS 인증서 통합

### 📦 **Helm 고급 활용**
- 차트 템플릿 고급 기법
- Values.yaml 계층 구조
- Helm Hook 활용
- 차트 의존성 관리

### 🐳 **컨테이너 최적화**
- 멀티 스테이지 빌드
- 이미지 최적화 기법
- Health Check 구성
- 리소스 제한 설정

---

## 🚀 실습 가이드

### 1. ArgoCD GitOps 실습

#### ArgoCD 설치
```bash
cd practice/argocd/

# ArgoCD 네임스페이스 생성
kubectl create namespace argocd

# ArgoCD 설치
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 관리자 패스워드 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# ArgoCD UI 접속
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 애플리케이션 배포
```yaml
# application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
# 애플리케이션 배포
kubectl apply -f application.yaml

# 동기화 확인
kubectl get application -n argocd
```

---

### 2. AWS Load Balancer Controller 설정

#### 컨트롤러 설치
```bash
cd practice/setup_alb_controller/

# IAM 정책 생성
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 서비스 어카운트 생성
eksctl create iamserviceaccount \
  --cluster=<your-cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Helm으로 컨트롤러 설치
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

#### ALB Ingress 설정
```yaml
# alb-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-2048
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: service-2048
              port:
                number: 80
```

---

### 3. Helm 차트 고급 실습

#### 커스텀 차트 생성
```bash
cd practice/helm/

# 새 차트 생성
helm create my-webapp

# 차트 구조 확인
tree my-webapp/
```

#### Values.yaml 고급 구성
```yaml
# values.yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  hosts:
    - host: my-webapp.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}
```

#### 배포 및 관리
```bash
# 차트 검증
helm lint my-webapp/

# 템플릿 렌더링 확인
helm template my-webapp my-webapp/

# 차트 설치
helm install my-webapp my-webapp/

# 업그레이드
helm upgrade my-webapp my-webapp/

# 롤백
helm rollback my-webapp 1

# 상태 확인
helm status my-webapp
helm list
```

---

### 4. 컨테이너 최적화 실습

#### 멀티 스테이지 Dockerfile
```dockerfile
# multi-stage.dockerfile
# Build stage
FROM node:16-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Production stage
FROM node:16-alpine AS production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

WORKDIR /app
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT 3000

CMD ["node", "server.js"]
```

#### 리소스 제한 설정
```yaml
# deployment-with-limits.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: my-webapp:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

### 5. Terraform 고급 실습

#### 모듈화된 구조
```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name = "practice-cluster"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

module "addons" {
  source = "./modules/addons"
  
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
}
```

#### 동적 구성
```hcl
# variables.tf
variable "environments" {
  description = "List of environments"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    max_size      = number
    min_size      = number
  }))
  
  default = {
    dev = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size      = 4
      min_size      = 1
    }
    prod = {
      instance_types = ["m5.large"]
      desired_size   = 3
      max_size      = 10
      min_size      = 2
    }
  }
}
```

---

## 🔍 모니터링 및 디버깅

### ArgoCD 상태 확인
```bash
# 애플리케이션 상태
kubectl get application -n argocd

# 동기화 히스토리
argocd app history guestbook

# 로그 확인
kubectl logs -n argocd deployment/argocd-application-controller
```

### ALB 상태 확인
```bash
# ALB 컨트롤러 로그
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

# 인그레스 상태
kubectl describe ingress <ingress-name>

# AWS 로드 밸런서 확인 (AWS 콘솔)
```

### 리소스 사용률 모니터링
```bash
# 파드 리소스 사용률
kubectl top pods

# 노드 리소스 사용률
kubectl top nodes

# HPA 상태 확인
kubectl get hpa
kubectl describe hpa <hpa-name>
```

---

## 🔧 트러블슈팅

### 일반적인 문제 해결

#### ArgoCD 동기화 실패
```bash
# 애플리케이션 상세 정보
argocd app get <app-name>

# 수동 동기화
argocd app sync <app-name>

# Git 리포지토리 접근 확인
argocd repo list
```

#### ALB 생성 실패
```bash
# 컨트롤러 로그 확인
kubectl logs -f -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# IAM 권한 확인
# AWS 서비스 한도 확인
```

#### Helm 배포 실패
```bash
# 릴리스 상태 확인
helm status <release-name>

# 롤백
helm rollback <release-name> <revision>

# 히스토리 확인
helm history <release-name>
```

---

## 📖 다음 단계

Project 02 완료 후 추천 학습 경로:

1. **[Project 03](../project03/README.md)**: 프로덕션급 EKS 클러스터
   - Istio 서비스 메시
   - Karpenter 자동 스케일링
   - 완전한 모니터링 스택

2. **[EKS 전용 구성](../eks_jenkins/README.md)**: CI/CD 파이프라인
   - Jenkins 통합
   - GitHub Actions
   - GitLab CI/CD

3. **[Project 04](../project04/README.md)**: 보안 강화 환경
   - Bottlerocket OS
   - Keycloak 인증
   - Trivy 보안 스캐닝

---

## 🔗 관련 링크

- [📖 메인 README](../README.md)
- [📖 Project 01 (기초)](../project01/README.md)
- [🔧 ArgoCD 문서](https://argo-cd.readthedocs.io/)
- [🔧 AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [🔧 Helm 문서](https://helm.sh/docs/)
- [🔧 Terraform 문서](https://www.terraform.io/docs/)

---

## 🤝 기여 및 피드백

실습 과정에서의 피드백을 환영합니다:
- 실습 난이도 조정 제안
- 추가 실습 시나리오 요청
- 도구별 고급 기능 제안
- 문서 개선 사항 