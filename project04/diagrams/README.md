# Project 04 - 아키텍처 다이어그램

이 디렉토리는 Project 04 (Bottlerocket 기반 보안 강화 EKS 클러스터)의 아키텍처를 시각화한 다이어그램들을 포함합니다.

## 📋 다이어그램 목록

### 🎯 간결하고 명확한 아키텍처 (한 눈에 들어오는 구조)

#### 1. 메인 아키텍처 (`main_architecture.py`)
- **파일**: `main_architecture.png`
- **내용**: 핵심 구성 요소만 포함한 간결한 전체 아키텍처
- **특징**: [diagrams.mingrammer.com 예제](https://diagrams.mingrammer.com/docs/getting-started/examples)처럼 한 눈에 들어오는 구조

#### 2. 보안 아키텍처 (`security_architecture.py`)
- **파일**: `security_architecture.png`
- **내용**: 핵심 보안 요소만 포함한 간결한 보안 구조

#### 3. 모니터링 아키텍처 (`monitoring_architecture.py`)
- **파일**: `monitoring_architecture.png`
- **내용**: 핵심 모니터링 요소만 포함한 간결한 관측성 구조

#### 4. Istio Ambient Mesh (`istio_ambient_architecture.py`)
- **파일**: `istio_ambient_architecture.png`
- **내용**: Ambient 모드의 핵심 구성 요소만 포함

#### 5. Istio Sidecar Mesh (`istio_sidecar_architecture.py`)
- **파일**: `istio_sidecar_architecture.png`
- **내용**: Sidecar 모드의 핵심 구성 요소만 포함

## 🚀 사용 방법

### 설치 및 실행
```bash
# 의존성 설치
pip install -r requirements.txt

# 모든 다이어그램 생성
python3 generate_all.py

# 개별 다이어그램 생성
python3 main_architecture.py
python3 security_architecture.py
python3 monitoring_architecture.py
python3 istio_ambient_architecture.py
python3 istio_sidecar_architecture.py
```

### 생성된 파일
- `main_architecture.png` - 메인 아키텍처
- `security_architecture.png` - 보안 아키텍처
- `monitoring_architecture.png` - 모니터링 아키텍처
- `istio_ambient_architecture.png` - Istio Ambient Mesh
- `istio_sidecar_architecture.png` - Istio Sidecar Mesh

## 🛠️ 커스터마이징

### 다이어그램 수정
1. 해당 Python 파일을 편집
2. `python3 [파일명].py` 실행하여 PNG 파일 재생성

### 새로운 다이어그램 추가
1. 새로운 Python 파일 생성
2. `generate_all.py`에 파일명 추가
3. `python3 generate_all.py` 실행

### Custom 아이콘 사용
[diagrams.mingrammer.com의 Custom 노드 문서](https://diagrams.mingrammer.com/docs/nodes/custom)를 참고하여 커스텀 아이콘을 사용할 수 있습니다.

#### 필요한 아이콘 파일들
다음 아이콘 파일들을 `icons/` 디렉토리에 추가해야 합니다:
- `keycloak.png` - Keycloak 인증 서버
- `trivy.png` - Trivy 보안 스캐너
- `falco.png` - Falco 런타임 보안
- `bottlerocket.png` - Bottlerocket OS
- `alloy.png` - Grafana Alloy

**참고**: Ztunnel은 Istio의 구성 요소이므로 Istio 로고를 사용합니다.

#### Custom 아이콘 사용 예시
```python
from diagrams.custom import Custom

# Custom 아이콘 사용
keycloak = Custom("Keycloak", "./icons/keycloak.png")
trivy = Custom("Trivy", "./icons/trivy.png")
```

## 📚 참고 자료

- [Diagrams 공식 문서](https://diagrams.mingrammer.com/)
- [Diagrams 예제](https://diagrams.mingrammer.com/docs/getting-started/examples)
- [Project 04 README](../README.md)

## 🎨 특징

- **간결성**: 핵심 구성 요소만 포함하여 복잡도 최소화
- **가독성**: 한 눈에 아키텍처를 파악할 수 있는 명확한 구조
- **효율성**: 작은 파일 크기로 빠른 로딩과 공유 가능
- **명확성**: 각 구성 요소의 역할과 관계가 명확하게 표현