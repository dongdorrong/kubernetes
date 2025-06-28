# Kyverno 테스트 리포트

**테스트 시작 시간**: 2025-05-31 16:57:21  
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

16:57:21 [INFO] 리소스 정리

## 리소스 정리

**정리 시작 시간**: 2025-05-31 16:57:21

16:57:23 [INFO] 정리 완료
✅ 모든 리소스 정리 완료

## 정리 후 노드 상태

**시간**: 2025-05-31 16:57:23

### 노드 기본 정보
```
NAME          STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                       CONTAINER-RUNTIME
dongdorrong   Ready    control-plane,master   66m   v1.32.5+k3s1   172.25.237.158   <none>        Ubuntu 24.04.2 LTS   5.15.153.1-microsoft-standard-WSL2   containerd://2.0.5-k3s1.32
```

### 리소스 할당 현황
```
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests       Limits
  --------           --------       ------
  cpu                19700m (82%)   27900m (116%)
  memory             13644Mi (85%)  23466Mi (147%)
  ephemeral-storage  0 (0%)         0 (0%)
  hugepages-1Gi      0 (0%)         0 (0%)
  hugepages-2Mi      0 (0%)         0 (0%)
Events:              <none>
```

### 현재 실행 중인 파드
```
NAMESPACE     NAME                                                 READY   STATUS      RESTARTS   AGE     IP            NODE          NOMINATED NODE   READINESS GATES
default       dummy-10-dummy-app-5b9d6b9d47-pztgp                  1/1     Running     0          3m27s   10.42.0.95    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-high-resource-68d77bb57d-6bhgm    1/1     Running     0          3m27s   10.42.0.94    dongdorrong   <none>           <none>
default       dummy-10-dummy-app-no-limits-5dc8c9448f-stv95        1/1     Running     0          3m27s   10.42.0.96    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-bb588988-zrx72                    1/1     Running     0          3m25s   10.42.0.97    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-high-resource-6dc87bdb5f-fsvtw    1/1     Running     0          3m25s   10.42.0.98    dongdorrong   <none>           <none>
default       dummy-11-dummy-app-no-limits-7d7b4b8b7b-g4x7x        1/1     Running     0          3m25s   10.42.0.99    dongdorrong   <none>           <none>
default       dummy-12-dummy-app-55fbfb5-mw6p8                     1/1     Running     0          3m22s   10.42.0.102   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-high-resource-b59d6d9cb-9jbrn     1/1     Running     0          3m22s   10.42.0.100   dongdorrong   <none>           <none>
default       dummy-12-dummy-app-no-limits-5f9bbff575-fv6wt        1/1     Running     0          3m22s   10.42.0.101   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-687fdbfc86-hnqcv                  1/1     Running     0          3m10s   10.42.0.103   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-high-resource-7ccf69964f-7sq7g    1/1     Running     0          3m10s   10.42.0.105   dongdorrong   <none>           <none>
default       dummy-13-dummy-app-no-limits-b8849b8c4-22cc4         1/1     Running     0          3m10s   10.42.0.104   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-5f8557f555-b58vp                  1/1     Running     0          3m8s    10.42.0.108   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-high-resource-5f94b776b6-7dxjr    1/1     Running     0          3m8s    10.42.0.106   dongdorrong   <none>           <none>
default       dummy-14-dummy-app-no-limits-7cc7f549c7-6w2zb        1/1     Running     0          3m8s    10.42.0.107   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-fc75f544-kbfk8                    1/1     Running     0          2m55s   10.42.0.109   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-high-resource-5df6d8f9bc-7ktkw    1/1     Running     0          2m55s   10.42.0.110   dongdorrong   <none>           <none>
default       dummy-15-dummy-app-no-limits-55884ff8d4-qjft5        1/1     Running     0          2m55s   10.42.0.111   dongdorrong   <none>           <none>
default       dummy-3-dummy-app-7d454fc9df-ncmnh                   1/1     Running     0          4m12s   10.42.0.75    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-high-resource-79f8474f9b-wltpv     1/1     Running     0          4m12s   10.42.0.73    dongdorrong   <none>           <none>
default       dummy-3-dummy-app-no-limits-7d88889b8c-kt9nd         1/1     Running     0          4m12s   10.42.0.74    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-76bd767bdb-k5bvh                   1/1     Running     0          4m      10.42.0.77    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-high-resource-75f7f978b9-nrhv4     1/1     Running     0          4m      10.42.0.76    dongdorrong   <none>           <none>
default       dummy-4-dummy-app-no-limits-745dcfd6f4-vnsgm         1/1     Running     0          4m      10.42.0.78    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-7c8f496b87-66lf8                   1/1     Running     0          3m58s   10.42.0.81    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-high-resource-6b56c9d4b-nrzjq      1/1     Running     0          3m58s   10.42.0.80    dongdorrong   <none>           <none>
default       dummy-5-dummy-app-no-limits-6585655dd5-68bhm         1/1     Running     0          3m58s   10.42.0.79    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-5784d4cf8d-t4b6l                   1/1     Running     0          3m56s   10.42.0.82    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-high-resource-5fbcfb9d87-hlsq6     1/1     Running     0          3m56s   10.42.0.83    dongdorrong   <none>           <none>
default       dummy-6-dummy-app-no-limits-b4668c7d4-p599c          1/1     Running     0          3m56s   10.42.0.84    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-859545ccb5-9n2k4                   1/1     Running     0          3m44s   10.42.0.87    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-high-resource-b564dcc56-kmcjb      1/1     Running     0          3m44s   10.42.0.85    dongdorrong   <none>           <none>
default       dummy-7-dummy-app-no-limits-8fccc6b47-s4n8w          1/1     Running     0          3m44s   10.42.0.86    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-68d46566f4-m5smz                   1/1     Running     0          3m41s   10.42.0.88    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-high-resource-85c77b5bf7-hhrq7     1/1     Running     0          3m41s   10.42.0.90    dongdorrong   <none>           <none>
default       dummy-8-dummy-app-no-limits-8747c8f86-mrskd          1/1     Running     0          3m41s   10.42.0.89    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-5bc88c8dc-dnl58                    1/1     Running     0          3m39s   10.42.0.92    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-high-resource-bb5c9d85d-58852      1/1     Running     0          3m39s   10.42.0.91    dongdorrong   <none>           <none>
default       dummy-9-dummy-app-no-limits-6fd77c8bf7-pz7k6         1/1     Running     0          3m39s   10.42.0.93    dongdorrong   <none>           <none>
default       test-high-dummy-app-67fc48c4d5-8hzhz                 1/1     Running     0          2m47s   10.42.0.114   dongdorrong   <none>           <none>
default       test-high-dummy-app-high-resource-5d5d5d89f4-bxlkh   1/1     Running     0          2m47s   10.42.0.112   dongdorrong   <none>           <none>
default       test-high-dummy-app-no-limits-684b5fd5d7-qmvlt       1/1     Running     0          2m47s   10.42.0.113   dongdorrong   <none>           <none>
default       test-low-dummy-app-56d6785ff9-gx4vq                  1/1     Running     0          2m44s   10.42.0.115   dongdorrong   <none>           <none>
default       test-low-dummy-app-high-resource-68578fbfb-lrr5m     1/1     Running     0          2m44s   10.42.0.117   dongdorrong   <none>           <none>
default       test-low-dummy-app-no-limits-585ff56bfc-j7tnn        1/1     Running     0          2m44s   10.42.0.116   dongdorrong   <none>           <none>
kube-system   coredns-697968c856-jqj2s                             1/1     Running     0          66m     10.42.0.4     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-97g6p                           0/1     Completed   1          66m     10.42.0.5     dongdorrong   <none>           <none>
kube-system   helm-install-traefik-crd-mjljj                       0/1     Completed   0          66m     10.42.0.6     dongdorrong   <none>           <none>
kube-system   local-path-provisioner-774c6665dc-882j7              1/1     Running     0          66m     10.42.0.3     dongdorrong   <none>           <none>
kube-system   metrics-server-6f4c6675d5-9tgjj                      1/1     Running     0          66m     10.42.0.2     dongdorrong   <none>           <none>
kube-system   svclb-traefik-c082f6f0-qrfdz                         2/2     Running     0          66m     10.42.0.7     dongdorrong   <none>           <none>
kube-system   traefik-c98fdf6fb-g9nvs                              1/1     Running     0          66m     10.42.0.8     dongdorrong   <none>           <none>
kyverno       kyverno-admission-controller-6d55595bd5-d44p4        1/1     Running     0          54m     10.42.0.9     dongdorrong   <none>           <none>
kyverno       kyverno-background-controller-5fccfb6b67-x8726       1/1     Running     0          54m     10.42.0.12    dongdorrong   <none>           <none>
kyverno       kyverno-cleanup-controller-6867df796b-zj9tz          1/1     Running     0          54m     10.42.0.11    dongdorrong   <none>           <none>
kyverno       kyverno-reports-controller-565dc659dd-mkhmh          1/1     Running     0          54m     10.42.0.10    dongdorrong   <none>           <none>
```

### 실시간 리소스 사용량
```
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
dongdorrong   265m         1%       3755Mi          23%         
```

---


---

## 테스트 완료

**테스트 종료 시간**: 2025-05-31 16:57:23
**리포트 파일**: kyverno-test-report-20250531-165721.md

### 요약
- 더미 앱 배포를 통한 노드 리소스 사용량 증가 확인
- Kyverno 정책을 통한 CPU 제한 제어 확인
- 정책 적용 전후 리소스 사용량 변화 측정

16:57:23 [INFO] 리포트가 kyverno-test-report-20250531-165721.md 에 저장되었습니다
