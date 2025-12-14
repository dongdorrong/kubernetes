# locals {
#   # kubectl apply -f 명령으로 수동 배포할 매니페스트 파일을 아래 배열에 추가하세요.
#   # 예시)
#   # manual_yaml_manifests = [
#   #   "ingress-for-addons.yaml",
#   #   "istio-gateway.yaml",
#   # ]
#   manual_yaml_manifests = [
#     # "s3-mount-test.yaml",
#   ]
# }

# locals {
#   manual_yaml_commands = [
#     for manifest in local.manual_yaml_manifests :
#     "kubectl apply -f ${path.root}/manifests/${manifest}"
#   ]
# }

# output "manual_kubectl_apply_commands" {
#   description = "수동 배포용 kubectl apply 명령어 목록"
#   value       = local.manual_yaml_commands
# }
