# Kyverno 테스트 리포트

**테스트 시작 시간**: 2025-05-31 16:53:06  
**테스트 환경**: k3s 클러스터  
**목적**: CPU 리소스 요청/제한에 대한 Kyverno 정책 효과 검증

## 테스트 개요

1. 더미 앱 15개 배포하여 노드 리소스 50-60% 사용
2. Kyverno 정책 배포 (CPU 제한을 300m으로 제한)
3. 정책 효과 확인
4. 리소스 사용량 변화 측정

---

## 디렉토리 구조

```
/home/dongdorrong/github/private/kubernetes/k3-kyverno-test/
├── dummy-app/           # Helm 차트
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── kyverno/            # Kyverno Helm 차트
├── kyverno-policy/     # 정책 파일들
├── simple-test.sh      # 기본 테스트 스크립트
└── test-with-report.sh # 리포트 생성 스크립트
```

---

16:53:06 [INFO] 전체 테스트 시작
16:53:06 [INFO] 1단계: 더미 앱들을 배포하여 노드 리소스 50-60% 사용

## 1단계: 더미 앱 배포

**목표**: 각 앱당 800m CPU 요청, 1000m CPU 제한으로 15개 배포
**예상 총 CPU 요청**: 12000m (50%)
**예상 총 CPU 제한**: 15000m (62.5%)


## 배포 전 노드 상태

**시간**: 2025-05-31 16:53:06

### 노드 기본 정보
```
NAME          STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                       CONTAINER-RUNTIME
dongdorrong   Ready    control-plane,master   62m   v1.32.5+k3s1   172.25.237.158   <none>        Ubuntu 24.04.2 LTS   5.15.153.1-microsoft-standard-WSL2   containerd://2.0.5-k3s1.32
```

### 리소스 할당 현황
```
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                600m (2%)   100m (0%)
  memory             460Mi (2%)  938Mi (5%)
  ephemeral-storage  0 (0%)      0 (0%)
  hugepages-1Gi      0 (0%)      0 (0%)
  hugepages-2Mi      0 (0%)      0 (0%)
Events:              <none>
```

### 현재 실행 중인 파드
```
NAMESPACE     NAME                                             READY   STATUS      RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
kube-system   coredns-697968c856-jqj2s                         1/1     Running     0          62m   10.42.0.4    dongdorrong   <none>           <none>
kube-system   helm-install-traefik-97g6p                       0/1     Completed   1          62m   10.42.0.5    dongdorrong   <none>           <none>
kube-system   helm-install-traefik-crd-mjljj                   0/1     Completed   0          62m   10.42.0.6    dongdorrong   <none>           <none>
kube-system   local-path-provisioner-774c6665dc-882j7          1/1     Running     0          62m   10.42.0.3    dongdorrong   <none>           <none>
kube-system   metrics-server-6f4c6675d5-9tgjj                  1/1     Running     0          62m   10.42.0.2    dongdorrong   <none>           <none>
kube-system   svclb-traefik-c082f6f0-qrfdz                     2/2     Running     0          62m   10.42.0.7    dongdorrong   <none>           <none>
kube-system   traefik-c98fdf6fb-g9nvs                          1/1     Running     0          62m   10.42.0.8    dongdorrong   <none>           <none>
kyverno       kyverno-admission-controller-6d55595bd5-d44p4    1/1     Running     0          50m   10.42.0.9    dongdorrong   <none>           <none>
kyverno       kyverno-background-controller-5fccfb6b67-x8726   1/1     Running     0          50m   10.42.0.12   dongdorrong   <none>           <none>
kyverno       kyverno-cleanup-controller-6867df796b-zj9tz      1/1     Running     0          50m   10.42.0.11   dongdorrong   <none>           <none>
kyverno       kyverno-reports-controller-565dc659dd-mkhmh      1/1     Running     0          50m   10.42.0.10   dongdorrong   <none>           <none>
```

### 실시간 리소스 사용량
```
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
dongdorrong   150m         0%       2554Mi          16%         
```

---

16:53:06 [INFO] 더미 앱 1 배포 중...
✅ dummy-1 배포 성공
16:53:08 [INFO] 더미 앱 2 배포 중...
✅ dummy-2 배포 성공
16:53:10 [INFO] 더미 앱 3 배포 중...
✅ dummy-3 배포 성공
16:53:23 [INFO] 더미 앱 4 배포 중...
✅ dummy-4 배포 성공
16:53:25 [INFO] 더미 앱 5 배포 중...
✅ dummy-5 배포 성공
16:53:27 [INFO] 현재까지 5개 배포 시도 완료 (성공: 5, 실패: 0)
현재 실행 중인 더미 파드 수: 15
16:53:27 [INFO] 더미 앱 6 배포 중...
✅ dummy-6 배포 성공
16:53:39 [INFO] 더미 앱 7 배포 중...
✅ dummy-7 배포 성공
16:53:41 [INFO] 더미 앱 8 배포 중...
✅ dummy-8 배포 성공
16:53:44 [INFO] 더미 앱 9 배포 중...
✅ dummy-9 배포 성공
16:53:56 [INFO] 더미 앱 10 배포 중...
✅ dummy-10 배포 성공
16:53:58 [INFO] 현재까지 10개 배포 시도 완료 (성공: 10, 실패: 0)
현재 실행 중인 더미 파드 수: 30
16:53:58 [INFO] 더미 앱 11 배포 중...
✅ dummy-11 배포 성공
16:54:00 [INFO] 더미 앱 12 배포 중...
✅ dummy-12 배포 성공
16:54:13 [INFO] 더미 앱 13 배포 중...
✅ dummy-13 배포 성공
16:54:15 [INFO] 더미 앱 14 배포 중...
✅ dummy-14 배포 성공
16:54:27 [INFO] 더미 앱 15 배포 중...
✅ dummy-15 배포 성공
16:54:30 [INFO] 현재까지 15개 배포 시도 완료 (성공: 15, 실패: 0)
현재 실행 중인 더미 파드 수: 45
16:54:30 [INFO] 모든 더미 앱 배포 완료 (성공: 15, 실패: 0)

**배포 결과**: 성공 15개, 실패 0개


## 배포 후 노드 상태

**시간**: 2025-05-31 16:54:30

### 노드 기본 정보
```
NAME          STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                       CONTAINER-RUNTIME
dongdorrong   Ready    control-plane,master   64m   v1.32.5+k3s1   172.25.237.158   <none>        Ubuntu 24.04.2 LTS   5.15.153.1-microsoft-standard-WSL2   containerd://2.0.5-k3s1.32
```

### 리소스 할당 현황
```
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests       Limits
  --------           --------       ------
  cpu                21600m (90%)   30100m (125%)
  memory             13900Mi (87%)  23978Mi (150%)
  ephemeral-storage  0 (0%)         0 (0%)
  hugepages-1Gi      0 (0%)         0 (0%)
  hugepages-2Mi      0 (0%)         0 (0%)
Events:              <none>
```

### 현재 실행 중인 파드
```
NAMESPACE     NAME                                                READY   STATUS      RESTARTS   AGE   IP            NODE          NOMINATED NODE   READINESS GATES
default       dummy-1-dummy-app-67d6596fbc-knp7f                  1/1     Running     0          84s   10.42.0.69    dongdorrong   <none>           <none>
default       dummy-1-dummy-app-high-resource-76769bd998-ftqgl    1/1     Running     0          84s   10.42.0.67    dongdorrong   <none>           <none>
default       dummy-1-dummy-app-no-limits-5497cfb4f7-xr8gb        1/1     Running     0          84s   10.42.0.68    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-5b9d6b9d47-pztgp                 1/1     Running     0          34s   10.42.0.95    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-high-resource-68d77bb57d-6bhgm   1/1     Running     0          34s   10.42.0.94    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-no-limits-5dc8c9448f-stv95       1/1     Running     0          34s   10.42.0.96    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-bb588988-zrx72                   1/1     Running     0          32s   10.42.0.97    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-high-resource-6dc87bdb5f-fsvtw   1/1     Running     0          32s   10.42.0.98    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-no-limits-7d7b4b8b7b-g4x7x       1/1     Running     0          32s   10.42.0.99    dongdorrong   <none>           <none>
default       dummy-12-dummy-app-55fbfb5-mw6p8                    1/1     Running     0          29s   10.42.0.102   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-high-resource-b59d6d9cb-9jbrn    1/1     Running     0          29s   10.42.0.100   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-no-limits-5f9bbff575-fv6wt       1/1     Running     0          29s   10.42.0.101   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-687fdbfc86-hnqcv                 1/1     Running     0          17s   10.42.0.103   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-high-resource-7ccf69964f-7sq7g   1/1     Running     0          17s   10.42.0.105   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-no-limits-b8849b8c4-22cc4        1/1     Running     0          17s   10.42.0.104   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-5f8557f555-b58vp                 1/1     Running     0          15s   10.42.0.108   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-high-resource-5f94b776b6-7dxjr   1/1     Running     0          15s   10.42.0.106   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-no-limits-7cc7f549c7-6w2zb       1/1     Running     0          15s   10.42.0.107   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-fc75f544-kbfk8                   1/1     Running     0          2s    10.42.0.109   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-high-resource-5df6d8f9bc-7ktkw   1/1     Running     0          2s    10.42.0.110   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-no-limits-55884ff8d4-qjft5       1/1     Running     0          2s    10.42.0.111   dongdorrong   <none>           <none>
default       dummy-2-dummy-app-75598fdd76-dnplj                  1/1     Running     0          82s   10.42.0.71    dongdorrong   <none>           <none>
default       dummy-2-dummy-app-high-resource-cd4ccd59f-hcg2g     1/1     Running     0          82s   10.42.0.70    dongdorrong   <none>           <none>
default       dummy-2-dummy-app-no-limits-d9c699b9b-gzvr9         1/1     Running     0          82s   10.42.0.72    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-7d454fc9df-ncmnh                  1/1     Running     0          79s   10.42.0.75    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-high-resource-79f8474f9b-wltpv    1/1     Running     0          79s   10.42.0.73    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-no-limits-7d88889b8c-kt9nd        1/1     Running     0          79s   10.42.0.74    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-76bd767bdb-k5bvh                  1/1     Running     0          67s   10.42.0.77    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-high-resource-75f7f978b9-nrhv4    1/1     Running     0          67s   10.42.0.76    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-no-limits-745dcfd6f4-vnsgm        1/1     Running     0          67s   10.42.0.78    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-7c8f496b87-66lf8                  1/1     Running     0          65s   10.42.0.81    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-high-resource-6b56c9d4b-nrzjq     1/1     Running     0          65s   10.42.0.80    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-no-limits-6585655dd5-68bhm        1/1     Running     0          65s   10.42.0.79    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-5784d4cf8d-t4b6l                  1/1     Running     0          63s   10.42.0.82    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-high-resource-5fbcfb9d87-hlsq6    1/1     Running     0          63s   10.42.0.83    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-no-limits-b4668c7d4-p599c         1/1     Running     0          63s   10.42.0.84    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-859545ccb5-9n2k4                  1/1     Running     0          51s   10.42.0.87    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-high-resource-b564dcc56-kmcjb     1/1     Running     0          51s   10.42.0.85    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-no-limits-8fccc6b47-s4n8w         1/1     Running     0          51s   10.42.0.86    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-68d46566f4-m5smz                  1/1     Running     0          48s   10.42.0.88    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-high-resource-85c77b5bf7-hhrq7    1/1     Running     0          48s   10.42.0.90    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-no-limits-8747c8f86-mrskd         1/1     Running     0          48s   10.42.0.89    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-5bc88c8dc-dnl58                   1/1     Running     0          46s   10.42.0.92    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-high-resource-bb5c9d85d-58852     1/1     Running     0          46s   10.42.0.91    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-no-limits-6fd77c8bf7-pz7k6        1/1     Running     0          46s   10.42.0.93    dongdorrong   <none>           <none>
kube-system   coredns-697968c856-jqj2s                            1/1     Running     0          64m   10.42.0.4     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-97g6p                          0/1     Completed   1          64m   10.42.0.5     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-crd-mjljj                      0/1     Completed   0          64m   10.42.0.6     dongdorrong   <none>           <none>
kube-system   local-path-provisioner-774c6665dc-882j7             1/1     Running     0          64m   10.42.0.3     dongdorrong   <none>           <none>
kube-system   metrics-server-6f4c6675d5-9tgjj                     1/1     Running     0          64m   10.42.0.2     dongdorrong   <none>           <none>
kube-system   svclb-traefik-c082f6f0-qrfdz                        2/2     Running     0          63m   10.42.0.7     dongdorrong   <none>           <none>
kube-system   traefik-c98fdf6fb-g9nvs                             1/1     Running     0          63m   10.42.0.8     dongdorrong   <none>           <none>
kyverno       kyverno-admission-controller-6d55595bd5-d44p4       1/1     Running     0          51m   10.42.0.9     dongdorrong   <none>           <none>
kyverno       kyverno-background-controller-5fccfb6b67-x8726      1/1     Running     0          51m   10.42.0.12    dongdorrong   <none>           <none>
kyverno       kyverno-cleanup-controller-6867df796b-zj9tz         1/1     Running     0          51m   10.42.0.11    dongdorrong   <none>           <none>
kyverno       kyverno-reports-controller-565dc659dd-mkhmh         1/1     Running     0          51m   10.42.0.10    dongdorrong   <none>           <none>
```

### 실시간 리소스 사용량
```
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
dongdorrong   661m         2%       3553Mi          22%         
```

---

16:54:30 [INFO] 현재 노드 리소스 사용량 확인
16:54:31 [INFO] 2단계: Kyverno 정책 배포

## 2단계: Kyverno 정책 배포

### 적용된 정책
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: limit-cpu-usage
  annotations:
    policies.kyverno.io/title: Limit CPU Usage
    policies.kyverno.io/category: Resource Management
    policies.kyverno.io/description: CPU 제한을 300m 이하로 제한
spec:
  validationFailureAction: enforce
  background: true
  rules:
    - name: check-cpu-limit
      match:
        any:
        - resources:
            kinds:
            - Pod
      validate:
        message: "CPU 제한은 300m을 초과할 수 없습니다"
        pattern:
          spec:
            containers:
            - name: "*"
              resources:
                limits:
                  cpu: "<=300m"
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: mutate-cpu-limits
  annotations:
    policies.kyverno.io/title: Mutate CPU Limits
    policies.kyverno.io/category: Resource Management
    policies.kyverno.io/description: CPU 제한이 300m을 초과하면 300m으로 변경
spec:
  rules:
    - name: reduce-cpu-limits
      match:
        any:
        - resources:
            kinds:
            - Pod
      mutate:
        patchStrategicMerge:
          spec:
            containers:
            - (name): "*"
              resources:
                limits:
                  cpu: "300m"
                requests:
                  cpu: "150m"
```

16:54:31 [INFO] Kyverno 정책 적용 완료
✅ Kyverno 정책 적용 성공

### 정책 상태 확인
```
NAME                ADMISSION   BACKGROUND   READY   AGE   MESSAGE
limit-cpu-usage     true        true         True    5s    Ready
mutate-cpu-limits   true        true         True    5s    Ready
```

16:54:36 [INFO] 3단계: 새로운 앱 배포하여 정책 효과 확인

## 3단계: 정책 효과 테스트

### 높은 CPU 제한 앱 배포 테스트 (1000m)
16:54:36 [INFO] 높은 CPU 제한으로 앱 배포 시도 (1000m - 정책 위반 예상)
16:54:38 [WARNING] ⚠️  높은 CPU 제한 앱이 배포되었습니다 (정책이 적용되지 않았거나 mutate됨)
⚠️ 높은 CPU 제한 앱 배포 성공 (정책이 mutate했을 가능성)

**실제 적용된 리소스 설정**:
```
    Limits:
      cpu:     300m
      memory:  256Mi
    Requests:
      cpu:        150m
      memory:     128Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-5xbnc (ro)
--
    Limits:
      cpu:     300m
      memory:  1Gi
    Requests:
      cpu:        150m
      memory:     512Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2pc9g (ro)
--
    Limits:
      cpu:  300m
    Requests:
      cpu:        150m
      memory:     128Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-x4nxl (ro)
Conditions:
```

### 낮은 CPU 제한 앱 배포 테스트 (200m)
16:54:39 [INFO] 낮은 CPU 제한으로 앱 배포 시도 (200m - 정책 통과 예상)
16:54:51 [INFO] ✅ 낮은 CPU 제한 앱이 성공적으로 배포되었습니다
✅ 낮은 CPU 제한 앱 배포 성공

**실제 적용된 리소스 설정**:
```
    Limits:
      cpu:     300m
      memory:  256Mi
    Requests:
      cpu:        150m
      memory:     128Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-rwzzw (ro)
--
    Limits:
      cpu:     300m
      memory:  1Gi
    Requests:
      cpu:        150m
      memory:     512Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-r4kw5 (ro)
--
    Limits:
      cpu:  300m
    Requests:
      cpu:        150m
      memory:     128Mi
    Liveness:     http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:http/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-s7vxr (ro)
Conditions:
```

16:54:51 [INFO] 4단계: 리소스 사용량 변화 확인

## 4단계: 리소스 사용량 변화 확인


## 정책 적용 후 노드 상태

**시간**: 2025-05-31 16:54:51

### 노드 기본 정보
```
NAME          STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                       CONTAINER-RUNTIME
dongdorrong   Ready    control-plane,master   64m   v1.32.5+k3s1   172.25.237.158   <none>        Ubuntu 24.04.2 LTS   5.15.153.1-microsoft-standard-WSL2   containerd://2.0.5-k3s1.32
```

### 리소스 할당 현황
```
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests       Limits
  --------           --------       ------
  cpu                22500m (93%)   31900m (132%)
  memory             15436Mi (96%)  26538Mi (166%)
  ephemeral-storage  0 (0%)         0 (0%)
  hugepages-1Gi      0 (0%)         0 (0%)
  hugepages-2Mi      0 (0%)         0 (0%)
Events:              <none>
```

### 현재 실행 중인 파드
```
NAMESPACE     NAME                                                 READY   STATUS      RESTARTS   AGE    IP            NODE          NOMINATED NODE   READINESS GATES
default       dummy-1-dummy-app-67d6596fbc-knp7f                   1/1     Running     0          105s   10.42.0.69    dongdorrong   <none>           <none>
default       dummy-1-dummy-app-high-resource-76769bd998-ftqgl     1/1     Running     0          105s   10.42.0.67    dongdorrong   <none>           <none>
default       dummy-1-dummy-app-no-limits-5497cfb4f7-xr8gb         1/1     Running     0          105s   10.42.0.68    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-5b9d6b9d47-pztgp                  1/1     Running     0          55s    10.42.0.95    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-high-resource-68d77bb57d-6bhgm    1/1     Running     0          55s    10.42.0.94    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-no-limits-5dc8c9448f-stv95        1/1     Running     0          55s    10.42.0.96    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-bb588988-zrx72                    1/1     Running     0          53s    10.42.0.97    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-high-resource-6dc87bdb5f-fsvtw    1/1     Running     0          53s    10.42.0.98    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-no-limits-7d7b4b8b7b-g4x7x        1/1     Running     0          53s    10.42.0.99    dongdorrong   <none>           <none>
default       dummy-12-dummy-app-55fbfb5-mw6p8                     1/1     Running     0          50s    10.42.0.102   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-high-resource-b59d6d9cb-9jbrn     1/1     Running     0          50s    10.42.0.100   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-no-limits-5f9bbff575-fv6wt        1/1     Running     0          50s    10.42.0.101   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-687fdbfc86-hnqcv                  1/1     Running     0          38s    10.42.0.103   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-high-resource-7ccf69964f-7sq7g    1/1     Running     0          38s    10.42.0.105   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-no-limits-b8849b8c4-22cc4         1/1     Running     0          38s    10.42.0.104   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-5f8557f555-b58vp                  1/1     Running     0          36s    10.42.0.108   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-high-resource-5f94b776b6-7dxjr    1/1     Running     0          36s    10.42.0.106   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-no-limits-7cc7f549c7-6w2zb        1/1     Running     0          36s    10.42.0.107   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-fc75f544-kbfk8                    1/1     Running     0          23s    10.42.0.109   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-high-resource-5df6d8f9bc-7ktkw    1/1     Running     0          23s    10.42.0.110   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-no-limits-55884ff8d4-qjft5        1/1     Running     0          23s    10.42.0.111   dongdorrong   <none>           <none>
default       dummy-2-dummy-app-75598fdd76-dnplj                   1/1     Running     0          103s   10.42.0.71    dongdorrong   <none>           <none>
default       dummy-2-dummy-app-high-resource-cd4ccd59f-hcg2g      1/1     Running     0          103s   10.42.0.70    dongdorrong   <none>           <none>
default       dummy-2-dummy-app-no-limits-d9c699b9b-gzvr9          1/1     Running     0          103s   10.42.0.72    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-7d454fc9df-ncmnh                   1/1     Running     0          100s   10.42.0.75    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-high-resource-79f8474f9b-wltpv     1/1     Running     0          100s   10.42.0.73    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-no-limits-7d88889b8c-kt9nd         1/1     Running     0          100s   10.42.0.74    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-76bd767bdb-k5bvh                   1/1     Running     0          88s    10.42.0.77    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-high-resource-75f7f978b9-nrhv4     1/1     Running     0          88s    10.42.0.76    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-no-limits-745dcfd6f4-vnsgm         1/1     Running     0          88s    10.42.0.78    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-7c8f496b87-66lf8                   1/1     Running     0          86s    10.42.0.81    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-high-resource-6b56c9d4b-nrzjq      1/1     Running     0          86s    10.42.0.80    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-no-limits-6585655dd5-68bhm         1/1     Running     0          86s    10.42.0.79    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-5784d4cf8d-t4b6l                   1/1     Running     0          84s    10.42.0.82    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-high-resource-5fbcfb9d87-hlsq6     1/1     Running     0          84s    10.42.0.83    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-no-limits-b4668c7d4-p599c          1/1     Running     0          84s    10.42.0.84    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-859545ccb5-9n2k4                   1/1     Running     0          72s    10.42.0.87    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-high-resource-b564dcc56-kmcjb      1/1     Running     0          72s    10.42.0.85    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-no-limits-8fccc6b47-s4n8w          1/1     Running     0          72s    10.42.0.86    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-68d46566f4-m5smz                   1/1     Running     0          69s    10.42.0.88    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-high-resource-85c77b5bf7-hhrq7     1/1     Running     0          69s    10.42.0.90    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-no-limits-8747c8f86-mrskd          1/1     Running     0          69s    10.42.0.89    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-5bc88c8dc-dnl58                    1/1     Running     0          67s    10.42.0.92    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-high-resource-bb5c9d85d-58852      1/1     Running     0          67s    10.42.0.91    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-no-limits-6fd77c8bf7-pz7k6         1/1     Running     0          67s    10.42.0.93    dongdorrong   <none>           <none>
default       test-high-dummy-app-67fc48c4d5-8hzhz                 1/1     Running     0          15s    10.42.0.114   dongdorrong   <none>           <none>
default       test-high-dummy-app-high-resource-5d5d5d89f4-bxlkh   1/1     Running     0          15s    10.42.0.112   dongdorrong   <none>           <none>
default       test-high-dummy-app-no-limits-684b5fd5d7-qmvlt       1/1     Running     0          15s    10.42.0.113   dongdorrong   <none>           <none>
default       test-low-dummy-app-56d6785ff9-gx4vq                  1/1     Running     0          12s    10.42.0.115   dongdorrong   <none>           <none>
default       test-low-dummy-app-high-resource-68578fbfb-lrr5m     1/1     Running     0          12s    10.42.0.117   dongdorrong   <none>           <none>
default       test-low-dummy-app-no-limits-585ff56bfc-j7tnn        1/1     Running     0          12s    10.42.0.116   dongdorrong   <none>           <none>
kube-system   coredns-697968c856-jqj2s                             1/1     Running     0          64m    10.42.0.4     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-97g6p                           0/1     Completed   1          64m    10.42.0.5     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-crd-mjljj                       0/1     Completed   0          64m    10.42.0.6     dongdorrong   <none>           <none>
kube-system   local-path-provisioner-774c6665dc-882j7              1/1     Running     0          64m    10.42.0.3     dongdorrong   <none>           <none>
kube-system   metrics-server-6f4c6675d5-9tgjj                      1/1     Running     0          64m    10.42.0.2     dongdorrong   <none>           <none>
kube-system   svclb-traefik-c082f6f0-qrfdz                         2/2     Running     0          64m    10.42.0.7     dongdorrong   <none>           <none>
kube-system   traefik-c98fdf6fb-g9nvs                              1/1     Running     0          64m    10.42.0.8     dongdorrong   <none>           <none>
kyverno       kyverno-admission-controller-6d55595bd5-d44p4        1/1     Running     0          51m    10.42.0.9     dongdorrong   <none>           <none>
kyverno       kyverno-background-controller-5fccfb6b67-x8726       1/1     Running     0          51m    10.42.0.12    dongdorrong   <none>           <none>
kyverno       kyverno-cleanup-controller-6867df796b-zj9tz          1/1     Running     0          51m    10.42.0.11    dongdorrong   <none>           <none>
kyverno       kyverno-reports-controller-565dc659dd-mkhmh          1/1     Running     0          51m    10.42.0.10    dongdorrong   <none>           <none>
```

### 실시간 리소스 사용량
```
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
dongdorrong   1229m        5%       3707Mi          23%         
```

---

16:54:51 [INFO] 현재 노드 리소스 사용량:
16:54:51 [INFO] 현재 노드 리소스 사용량 확인
16:54:52 [INFO] 배포된 파드들의 리소스 설정:
### 배포된 파드들의 리소스 설정
```
dummy-1-dummy-app-67d6596fbc-knp7f                   800m      1
dummy-1-dummy-app-high-resource-76769bd998-ftqgl     500m      1
dummy-1-dummy-app-no-limits-5497cfb4f7-xr8gb         100m      <none>
dummy-10-dummy-app-5b9d6b9d47-pztgp                  800m      1
dummy-10-dummy-app-high-resource-68d77bb57d-6bhgm    500m      1
dummy-10-dummy-app-no-limits-5dc8c9448f-stv95        100m      <none>
dummy-11-dummy-app-bb588988-zrx72                    800m      1
dummy-11-dummy-app-high-resource-6dc87bdb5f-fsvtw    500m      1
dummy-11-dummy-app-no-limits-7d7b4b8b7b-g4x7x        100m      <none>
dummy-12-dummy-app-55fbfb5-mw6p8                     800m      1
dummy-12-dummy-app-high-resource-b59d6d9cb-9jbrn     500m      1
dummy-12-dummy-app-no-limits-5f9bbff575-fv6wt        100m      <none>
dummy-13-dummy-app-687fdbfc86-hnqcv                  800m      1
dummy-13-dummy-app-high-resource-7ccf69964f-7sq7g    500m      1
dummy-13-dummy-app-no-limits-b8849b8c4-22cc4         100m      <none>
dummy-14-dummy-app-5f8557f555-b58vp                  800m      1
dummy-14-dummy-app-high-resource-5f94b776b6-7dxjr    500m      1
dummy-14-dummy-app-no-limits-7cc7f549c7-6w2zb        100m      <none>
dummy-15-dummy-app-fc75f544-kbfk8                    800m      1
dummy-15-dummy-app-high-resource-5df6d8f9bc-7ktkw    500m      1
dummy-15-dummy-app-no-limits-55884ff8d4-qjft5        100m      <none>
dummy-2-dummy-app-75598fdd76-dnplj                   800m      1
dummy-2-dummy-app-high-resource-cd4ccd59f-hcg2g      500m      1
dummy-2-dummy-app-no-limits-d9c699b9b-gzvr9          100m      <none>
dummy-3-dummy-app-7d454fc9df-ncmnh                   800m      1
dummy-3-dummy-app-high-resource-79f8474f9b-wltpv     500m      1
dummy-3-dummy-app-no-limits-7d88889b8c-kt9nd         100m      <none>
dummy-4-dummy-app-76bd767bdb-k5bvh                   800m      1
dummy-4-dummy-app-high-resource-75f7f978b9-nrhv4     500m      1
dummy-4-dummy-app-no-limits-745dcfd6f4-vnsgm         100m      <none>
dummy-5-dummy-app-7c8f496b87-66lf8                   800m      1
dummy-5-dummy-app-high-resource-6b56c9d4b-nrzjq      500m      1
dummy-5-dummy-app-no-limits-6585655dd5-68bhm         100m      <none>
dummy-6-dummy-app-5784d4cf8d-t4b6l                   800m      1
dummy-6-dummy-app-high-resource-5fbcfb9d87-hlsq6     500m      1
dummy-6-dummy-app-no-limits-b4668c7d4-p599c          100m      <none>
dummy-7-dummy-app-859545ccb5-9n2k4                   800m      1
dummy-7-dummy-app-high-resource-b564dcc56-kmcjb      500m      1
dummy-7-dummy-app-no-limits-8fccc6b47-s4n8w          100m      <none>
dummy-8-dummy-app-68d46566f4-m5smz                   800m      1
dummy-8-dummy-app-high-resource-85c77b5bf7-hhrq7     500m      1
dummy-8-dummy-app-no-limits-8747c8f86-mrskd          100m      <none>
dummy-9-dummy-app-5bc88c8dc-dnl58                    800m      1
dummy-9-dummy-app-high-resource-bb5c9d85d-58852      500m      1
dummy-9-dummy-app-no-limits-6fd77c8bf7-pz7k6         100m      <none>
test-high-dummy-app-67fc48c4d5-8hzhz                 150m      300m
test-high-dummy-app-high-resource-5d5d5d89f4-bxlkh   150m      300m
test-high-dummy-app-no-limits-684b5fd5d7-qmvlt       150m      300m
test-low-dummy-app-56d6785ff9-gx4vq                  150m      300m
test-low-dummy-app-high-resource-68578fbfb-lrr5m     150m      300m
test-low-dummy-app-no-limits-585ff56bfc-j7tnn        150m      300m
```

16:54:52 [INFO] 전체 테스트 완료
16:54:52 [INFO] 리포트가 kyverno-test-report-20250531-165306.md 에 저장되었습니다
