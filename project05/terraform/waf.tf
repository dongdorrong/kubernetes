# # kubectl을 사용해서 Istio Gateway 정보 조회
# data "kubectl_file_documents" "istio_gateway_manifest" {
#     content = file("${path.module}/manifests/istio-gateway.yaml")
# }

# # WAF 관련 로컬 변수
# locals {
#     # AWS 관리형 룰셋 정의 (알파벳 순서로 자동 우선순위 할당)
#     # FingerPrintRule이 0이므로, 관리형 룰셋은 1부터 시작
#     aws_managed_rule_groups = [
#         "AWSManagedRulesAdminProtectionRuleSet",
#         "AWSManagedRulesAmazonIpReputationList", 
#         "AWSManagedRulesAnonymousIpList",
#         "AWSManagedRulesCommonRuleSet",
#         "AWSManagedRulesKnownBadInputsRuleSet",
#         "AWSManagedRulesLinuxRuleSet",
#         "AWSManagedRulesSQLiRuleSet"
#     ]
    
#     # 룰셋별 우선순위 맵 생성 (역순으로 높은 우선순위)
#     rule_priorities = { for i, rule_name in reverse(local.aws_managed_rule_groups) : 
#         rule_name => i + 1 
#     }
    
#     # Istio Gateway 매니페스트에서 호스트 도메인들 추출
#     gateway_yaml = yamldecode(data.kubectl_file_documents.istio_gateway_manifest.documents[0])
#     gateway_hosts = try(local.gateway_yaml.spec.servers[0].hosts, [])
    
#     # 도메인에서 와일드카드(*.) 제거하고 기본 도메인 추출  
#     token_domains = [
#         for host in local.gateway_hosts : 
#         replace(host, "*.", "") if host != "*"
#     ]
# }

# resource "aws_wafv2_web_acl" "main" {
#     name        = local.cluster_name
#     scope       = "REGIONAL"

#     default_action {
#         allow {}
#     }

#     # Kubernetes Istio Gateway에서 자동으로 추출된 도메인들
#     token_domains = local.token_domains

#     rule {
#         name     = "FingerPrintRule"
#         priority = 0
#         action {
#             count {
#             }
#         }

#         statement {
#             rate_based_statement {
#                 aggregate_key_type    = "CUSTOM_KEYS"
#                 evaluation_window_sec = 300
#                 limit                 = 1000

#                 custom_key {
#                     ja3_fingerprint {
#                         fallback_behavior = "MATCH"
#                     }
#                 }
#             }
#         }

#         visibility_config {
#             cloudwatch_metrics_enabled = true
#             metric_name                = "FingerPrintRule"
#             sampled_requests_enabled   = true
#         }
#     }

#     # AWS 관리형 룰셋 자동 생성 (알파벳 순서로 우선순위 자동 할당)
#     dynamic "rule" {
#         for_each = local.aws_managed_rule_groups
#         content {
#             name     = "AWS-${rule.value}"
#             priority = local.rule_priorities[rule.value]

#             override_action {
#                 none {}
#             }

#             statement {
#                 managed_rule_group_statement {
#                     name        = rule.value
#                     vendor_name = "AWS"
#                 }
#             }

#             visibility_config {
#                 cloudwatch_metrics_enabled = true
#                 metric_name                = "AWS-${rule.value}"
#                 sampled_requests_enabled   = true
#             }
#         }
#     }

#     visibility_config {
#         cloudwatch_metrics_enabled = true
#         metric_name                = local.cluster_name
#         sampled_requests_enabled   = true
#     }
# }