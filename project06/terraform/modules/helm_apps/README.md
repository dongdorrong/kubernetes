# helm_apps module

간단한 Helm 배포를 모듈화한 구성입니다. `applications` 맵에 릴리스 정보를 정의하면 `enabled = true`인 항목만 `helm_release`로 생성합니다. 로컬 차트(`source = "local"`, `chart_path` 지정)와 원격 레포(`source = "remote"`, `repository`, `chart`, `chart_version` 지정)를 모두 지원하며, `values_files`에 절대 경로를 넣어 원하는 values.yaml을 적용할 수 있습니다.
