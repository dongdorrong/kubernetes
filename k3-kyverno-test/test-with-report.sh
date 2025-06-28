#!/bin/bash

# Kyverno 테스트 스크립트 (마크다운 리포트 포함)
set -e

echo "🚀 Kyverno 테스트 시작 (리포트 생성)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 리포트 파일 설정
REPORT_FILE="kyverno-test-report-$(date +%Y%m%d-%H%M%S).md"
TEST_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date '+%H:%M:%S') [INFO] $1" >> "$REPORT_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%H:%M:%S') [WARNING] $1" >> "$REPORT_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%H:%M:%S') [ERROR] $1" >> "$REPORT_FILE"
}

# 마크다운 헤더 생성
init_report() {
    cat > "$REPORT_FILE" << EOF
# Kyverno 테스트 리포트

**테스트 시작 시간**: $TEST_START_TIME  
**테스트 환경**: k3s 클러스터  
**목적**: CPU 리소스 요청/제한에 대한 Kyverno 정책 효과 검증

## 테스트 개요

1. 더미 앱 15개 배포하여 노드 리소스 50-60% 사용
2. Kyverno 정책 배포 (CPU 제한을 300m으로 제한)
3. 정책 효과 확인
4. 리소스 사용량 변화 측정

---

## 디렉토리 구조

\`\`\`
/home/dongdorrong/github/private/kubernetes/k3-kyverno-test/
├── dummy-app/           # Helm 차트
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── kyverno/            # Kyverno Helm 차트
├── kyverno-policy/     # 정책 파일들
├── simple-test.sh      # 기본 테스트 스크립트
└── test-with-report.sh # 리포트 생성 스크립트
\`\`\`

---

EOF
}

# 노드 리소스 정보를 마크다운으로 기록
record_node_resources() {
    local title="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "" >> "$REPORT_FILE"
    echo "## $title" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**시간**: $timestamp" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 노드 기본 정보
    echo "### 노드 기본 정보" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl get nodes -o wide >> "$REPORT_FILE" 2>/dev/null || echo "노드 정보 조회 실패" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 리소스 할당 현황
    echo "### 리소스 할당 현황" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl describe node | grep -A 15 "Allocated resources" >> "$REPORT_FILE" 2>/dev/null || echo "리소스 정보 조회 실패" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 파드 목록
    echo "### 현재 실행 중인 파드" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl get pods --all-namespaces -o wide >> "$REPORT_FILE" 2>/dev/null || echo "파드 정보 조회 실패" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Top 명령어 (가능한 경우)
    echo "### 실시간 리소스 사용량" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl top node >> "$REPORT_FILE" 2>/dev/null || echo "metrics-server가 준비되지 않았습니다" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 현재 노드 리소스 사용량 확인
check_node_resources() {
    print_status "현재 노드 리소스 사용량 확인"
    kubectl top node 2>/dev/null || echo "metrics-server가 준비되지 않았습니다"
    kubectl describe node | grep -A 10 "Allocated resources"
}

# 1단계: 더미 앱을 여러 개 배포하여 50-60% 리소스 사용
deploy_dummy_apps() {
    print_status "1단계: 더미 앱들을 배포하여 노드 리소스 50-60% 사용"
    
    echo "" >> "$REPORT_FILE"
    echo "## 1단계: 더미 앱 배포" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**목표**: 각 앱당 800m CPU 요청, 1000m CPU 제한으로 15개 배포" >> "$REPORT_FILE"
    echo "**예상 총 CPU 요청**: 12000m (50%)" >> "$REPORT_FILE"
    echo "**예상 총 CPU 제한**: 15000m (62.5%)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 배포 전 상태 기록
    record_node_resources "배포 전 노드 상태"
    
    local deployed_count=0
    local failed_count=0
    
    # 각 앱당 800m CPU 요청, 1000m CPU 제한으로 설정
    # 15개 배포하면 약 12000m (50%) 요청
    for i in {1..15}; do
        print_status "더미 앱 $i 배포 중..."
        
        if helm install dummy-$i ./dummy-app \
            --set resources.requests.cpu=800m \
            --set resources.requests.memory=256Mi \
            --set resources.limits.cpu=1000m \
            --set resources.limits.memory=512Mi \
            --wait --timeout=60s; then
            deployed_count=$((deployed_count + 1))
            echo "✅ dummy-$i 배포 성공" >> "$REPORT_FILE"
        else
            failed_count=$((failed_count + 1))
            echo "❌ dummy-$i 배포 실패" >> "$REPORT_FILE"
        fi
        
        # 5개마다 상태 확인
        if [ $((i % 5)) -eq 0 ]; then
            print_status "현재까지 $i개 배포 시도 완료 (성공: $deployed_count, 실패: $failed_count)"
            local current_pods=$(kubectl get pods | grep dummy- | wc -l)
            echo "현재 실행 중인 더미 파드 수: $current_pods" >> "$REPORT_FILE"
        fi
    done
    
    print_status "모든 더미 앱 배포 완료 (성공: $deployed_count, 실패: $failed_count)"
    echo "" >> "$REPORT_FILE"
    echo "**배포 결과**: 성공 $deployed_count개, 실패 $failed_count개" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 배포 후 상태 기록
    record_node_resources "배포 후 노드 상태"
    
    check_node_resources
}

# 2단계: Kyverno 정책 배포
deploy_kyverno_policies() {
    print_status "2단계: Kyverno 정책 배포"
    
    echo "" >> "$REPORT_FILE"
    echo "## 2단계: Kyverno 정책 배포" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 간단한 CPU 제한 정책 생성
    cat > cpu-limit-policy.yaml << 'EOF'
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
EOF

    echo "### 적용된 정책" >> "$REPORT_FILE"
    echo "\`\`\`yaml" >> "$REPORT_FILE"
    cat cpu-limit-policy.yaml >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if kubectl apply -f cpu-limit-policy.yaml; then
        print_status "Kyverno 정책 적용 완료"
        echo "✅ Kyverno 정책 적용 성공" >> "$REPORT_FILE"
    else
        print_error "Kyverno 정책 적용 실패"
        echo "❌ Kyverno 정책 적용 실패" >> "$REPORT_FILE"
    fi
    
    sleep 5
    
    # 정책 상태 확인
    echo "" >> "$REPORT_FILE"
    echo "### 정책 상태 확인" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl get clusterpolicy >> "$REPORT_FILE" 2>/dev/null || echo "정책 조회 실패" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 3단계: 새로운 앱 배포하여 정책 효과 확인
test_policy_effect() {
    print_status "3단계: 새로운 앱 배포하여 정책 효과 확인"
    
    echo "" >> "$REPORT_FILE"
    echo "## 3단계: 정책 효과 테스트" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 높은 CPU 제한 테스트
    echo "### 높은 CPU 제한 앱 배포 테스트 (1000m)" >> "$REPORT_FILE"
    print_status "높은 CPU 제한으로 앱 배포 시도 (1000m - 정책 위반 예상)"
    
    if helm install test-high ./dummy-app \
        --set resources.requests.cpu=500m \
        --set resources.limits.cpu=1000m \
        --wait --timeout=60s; then
        print_warning "⚠️  높은 CPU 제한 앱이 배포되었습니다 (정책이 적용되지 않았거나 mutate됨)"
        echo "⚠️ 높은 CPU 제한 앱 배포 성공 (정책이 mutate했을 가능성)" >> "$REPORT_FILE"
        
        echo "" >> "$REPORT_FILE"
        echo "**실제 적용된 리소스 설정**:" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        kubectl describe pod -l app.kubernetes.io/instance=test-high | grep -A 10 "Limits:" >> "$REPORT_FILE" 2>/dev/null || echo "파드 정보 조회 실패" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        print_status "✅ 높은 CPU 제한 앱 배포가 차단되었습니다 (정책 효과 확인)"
        echo "✅ 높은 CPU 제한 앱 배포 차단됨 (정책 효과 확인)" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    
    # 낮은 CPU 제한 테스트
    echo "### 낮은 CPU 제한 앱 배포 테스트 (200m)" >> "$REPORT_FILE"
    print_status "낮은 CPU 제한으로 앱 배포 시도 (200m - 정책 통과 예상)"
    
    if helm install test-low ./dummy-app \
        --set resources.requests.cpu=100m \
        --set resources.limits.cpu=200m \
        --wait --timeout=60s; then
        print_status "✅ 낮은 CPU 제한 앱이 성공적으로 배포되었습니다"
        echo "✅ 낮은 CPU 제한 앱 배포 성공" >> "$REPORT_FILE"
        
        echo "" >> "$REPORT_FILE"
        echo "**실제 적용된 리소스 설정**:" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        kubectl describe pod -l app.kubernetes.io/instance=test-low | grep -A 10 "Limits:" >> "$REPORT_FILE" 2>/dev/null || echo "파드 정보 조회 실패" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        print_error "❌ 낮은 CPU 제한 앱 배포가 실패했습니다"
        echo "❌ 낮은 CPU 제한 앱 배포 실패" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# 4단계: 리소스 사용량 변화 확인
check_resource_changes() {
    print_status "4단계: 리소스 사용량 변화 확인"
    
    echo "" >> "$REPORT_FILE"
    echo "## 4단계: 리소스 사용량 변화 확인" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 정책 적용 후 상태 기록
    record_node_resources "정책 적용 후 노드 상태"
    
    print_status "현재 노드 리소스 사용량:"
    check_node_resources
    
    print_status "배포된 파드들의 리소스 설정:"
    echo "### 배포된 파드들의 리소스 설정" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    kubectl get pods -o custom-columns="NAME:.metadata.name,CPU_REQ:.spec.containers[0].resources.requests.cpu,CPU_LIM:.spec.containers[0].resources.limits.cpu" | grep dummy >> "$REPORT_FILE" 2>/dev/null || echo "파드 리소스 정보 조회 실패" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 정리 함수
cleanup() {
    print_status "리소스 정리"
    
    echo "" >> "$REPORT_FILE"
    echo "## 리소스 정리" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local cleanup_start=$(date '+%Y-%m-%d %H:%M:%S')
    echo "**정리 시작 시간**: $cleanup_start" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 모든 더미 앱 제거
    for i in {1..15}; do
        helm uninstall dummy-$i --ignore-not-found=true 2>/dev/null || true
    done
    
    # 테스트 앱 제거
    helm uninstall test-high --ignore-not-found=true 2>/dev/null || true
    helm uninstall test-low --ignore-not-found=true 2>/dev/null || true
    
    # 정책 제거
    kubectl delete -f cpu-limit-policy.yaml --ignore-not-found=true 2>/dev/null || true
    rm -f cpu-limit-policy.yaml
    
    print_status "정리 완료"
    echo "✅ 모든 리소스 정리 완료" >> "$REPORT_FILE"
    
    # 정리 후 상태 기록
    record_node_resources "정리 후 노드 상태"
    
    # 리포트 마무리
    local test_end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## 테스트 완료" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**테스트 종료 시간**: $test_end_time" >> "$REPORT_FILE"
    echo "**리포트 파일**: $REPORT_FILE" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "### 요약" >> "$REPORT_FILE"
    echo "- 더미 앱 배포를 통한 노드 리소스 사용량 증가 확인" >> "$REPORT_FILE"
    echo "- Kyverno 정책을 통한 CPU 제한 제어 확인" >> "$REPORT_FILE"
    echo "- 정책 적용 전후 리소스 사용량 변화 측정" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 메인 함수
main() {
    # 리포트 초기화
    init_report
    
    case "${1:-all}" in
        "deploy")
            deploy_dummy_apps
            ;;
        "policies")
            deploy_kyverno_policies
            ;;
        "test")
            test_policy_effect
            ;;
        "check")
            check_resource_changes
            ;;
        "clean")
            cleanup
            ;;
        "all")
            print_status "전체 테스트 시작"
            deploy_dummy_apps
            deploy_kyverno_policies
            test_policy_effect
            check_resource_changes
            print_status "전체 테스트 완료"
            ;;
        *)
            echo "사용법: $0 [deploy|policies|test|check|clean|all]"
            echo "  deploy:   더미 앱 15개 배포 (50-60% 리소스 사용)"
            echo "  policies: Kyverno 정책 배포"
            echo "  test:     정책 효과 테스트"
            echo "  check:    리소스 사용량 확인"
            echo "  clean:    모든 리소스 정리"
            echo "  all:      전체 테스트 실행 (기본값)"
            exit 1
            ;;
    esac
    
    print_status "리포트가 $REPORT_FILE 에 저장되었습니다"
}

# 스크립트 실행
main "$@" 