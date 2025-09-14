# # Keda Helm 차트 설치
# # https://github.com/kubecost/cost-analyzer-helm-chart

# # 네임스페이스 생성
# resource "kubernetes_namespace" "deployment" {
#     metadata {
#         name = "deployment"
#     }
# }

# resource "helm_release" "keda" {
#     name            = "keda"
#     repository      = "https://kedacore.github.io/charts"
#     chart           = "keda"
#     namespace       = kubernetes_namespace.deployment.metadata[0].name
#     upgrade_install = true

#     values = [
#         yamlencode({
#             crds = {
#                 install = true
#             }
#         })
#     ]

#     depends_on = [
#         aws_eks_cluster.this
#     ]
# }

# # ArgoCD Helm 차트 설치
# # https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
# resource "helm_release" "argocd" {
#     name            = "argocd"
#     repository      = "https://argoproj.github.io/argo-helm"
#     chart           = "argo-cd"
#     namespace       = kubernetes_namespace.deployment.metadata[0].name
#     upgrade_install = true

#     values = [
#         yamlencode({
#             global = {
#                 domain = "argocd.dongdorrong.com"
#             }
#             configs = {
#                 cm = {
#                     url = "https://argocd.dongdorrong.com"
#                     "oidc.config" = <<-EOT
#                         name: Keycloak
#                         issuer: https://keycloak.dongdorrong.com/realms/dongdorrong-realm
#                         clientID: argo-cd-client
#                         clientSecret: $oidc.keycloak.clientSecret
#                         requestedScopes: ["openid", "profile", "email", "groups"]
#                         logoutURL: https://keycloak.dongdorrong.com/realms/dongdorrong-realm/protocol/openid-connect/logout?id_token_hint={{token}}&post_logout_redirect_uri=https://argocd.dongdorrong.com
#                     EOT
#                 }
#                 params = {
#                     "server.insecure" = true
#                 }
#                 secret = {
#                     extra = {
#                         "oidc.keycloak.clientSecret" = "aaaaaabbbbbbbcccccccddddddde"
#                     }
#                 }
#             }
#             notifications = {
#                 argocdUrl = "https://argocd.dongdorrong.com"
#                 context = {
#                     slackMessageUsername = "ArgoCD-Notification-OnPremise"
#                 }
#                 notifiers = {
#                     service = {
#                         webhook = {
#                             slack_webhook = {
#                                 url = "https://hooks.slack.com/services/T0000000000/B0000000000/XXXXXXXXXXXXXXXXXXXXXXXX"
#                                 headers = [{
#                                     name  = "Content-Type"
#                                     value = "application/json"
#                                 }]
#                             }
#                         }
#                     }
#                 }

#                 templates = {
#                     "template.app-deployed" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "New version of an application {{.app.metadata.name}} is up and running.",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#18be52",
#                                 "fields": [{
#                                     "title": "Sync Status",
#                                     "value": "{{.app.status.sync.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Revision",
#                                     "value": "{{.app.status.sync.revision}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT

#                     "template.app-health-degraded" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "Application {{.app.metadata.name}} has degraded.",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#f4c030",
#                                 "fields": [{
#                                     "title": "Health Status",
#                                     "value": "{{.app.status.health.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT

#                     "template.app-sync-failed" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "Failed to sync application {{.app.metadata.name}}.",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#E96D76",
#                                 "fields": [{
#                                     "title": "Sync Status",
#                                     "value": "{{.app.status.sync.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT

#                     "template.app-sync-running" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "Start syncing application {{.app.metadata.name}}.",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#F29661",
#                                 "fields": [{
#                                     "title": "Sync Status",
#                                     "value": "{{.app.status.sync.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT

#                     "template.app-sync-status-unknown" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "Application {{.app.metadata.name}} sync status is 'Unknown'",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#E96D76",
#                                 "fields": [{
#                                     "title": "Sync Status",
#                                     "value": "{{.app.status.sync.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT

#                     "template.app-sync-succeeded" = <<-EOT
#                         webhook:
#                         slack_webhook:
#                             method: POST
#                             body: |
#                             { 
#                                 "username": "{{.context.slackMessageUsername}}",
#                                 "attachments": [{
#                                 "pretext": "Application {{.app.metadata.name}} has been successfully synced.",
#                                 "author_name": "{{.app.metadata.name}}",
#                                 "author_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
#                                 "title": "",
#                                 "title_link": "",
#                                 "text": "",
#                                 "color": "#0DADEA",
#                                 "fields": [{
#                                     "title": "Sync Status",
#                                     "value": "{{.app.status.sync.status}}",
#                                     "short": false
#                                 }, {
#                                     "title": "Repository",
#                                     "value": "{{.app.spec.source.repoURL}}",
#                                     "short": false
#                                 }
#                                 {{range $index, $c := .app.status.conditions}}
#                                 {{if not $index}},{{end}}
#                                 {{if $index}},{{end}}
#                                 {
#                                     "title": "{{$c.type}}",
#                                     "value": "{{$c.message}}",
#                                     "short": true
#                                 }
#                                 {{end}}
#                                 ]
#                                 }]
#                             }
#                     EOT
#                 }

#                 triggers = {
#                     "trigger.on-deployed" = <<-EOT
#                         - description: Application is synced and healthy. Triggered once per commit.
#                         oncePer: app.status.operationState.syncResult.revision
#                         when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
#                         send: [app-deployed]
#                     EOT

#                     "trigger.on-health-degraded" = <<-EOT
#                         - description: Application has degraded
#                         when: app.status.health.status == 'Degraded'
#                         send: [app-health-degraded]
#                     EOT

#                     "trigger.on-sync-failed" = <<-EOT
#                         - description: Application syncing has failed
#                         when: app.status.operationState.phase in ['Error', 'Failed']
#                         send: [app-sync-failed]
#                     EOT

#                     "trigger.on-sync-running" = <<-EOT
#                         - description: Application is being synced
#                         when: app.status.operationState.phase in ['Running']
#                         send: [app-sync-running]
#                     EOT

#                     "trigger.on-sync-status-unknown" = <<-EOT
#                         - description: Application status is 'Unknown'
#                         when: app.status.sync.status == 'Unknown'
#                         send: [app-sync-status-unknown]
#                     EOT

#                     "trigger.on-sync-succeeded" = <<-EOT
#                         - description: Application syncing has succeeded
#                         when: app.status.operationState.phase in ['Succeeded']
#                         send: [app-sync-succeeded]
#                     EOT

#                     defaultTriggers = <<-EOT
#                         - on-sync-status-unknown
#                     EOT
#                 }

#                 subscriptions = [{
#                     recipients = [
#                         "slack_webhook:alert-develop"
#                     ]
#                     triggers = [
#                         "on-deployed",
#                         "on-health-degraded",
#                         "on-sync-failed",
#                         "on-sync-running",
#                         "on-sync-status-unknown",
#                         "on-sync-succeeded"
#                     ]
#                 }]
#             }
#         })
#     ]

#     depends_on = [
#         aws_eks_cluster.this
#     ]
# }
