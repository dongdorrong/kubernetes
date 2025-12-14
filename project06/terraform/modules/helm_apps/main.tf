locals {
  enabled_apps = {
    for key, app in var.applications : key => app
    if app.enabled
  }
}

resource "helm_release" "this" {
  for_each = local.enabled_apps

  name             = each.value.release_name
  namespace        = each.value.namespace
  create_namespace = lookup(each.value, "create_namespace", false)

  dynamic "set" {
    for_each = lookup(each.value, "set_values", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  values = [
    for file in lookup(each.value, "values_files", []) : file
  ]

  # Determine chart/repository fields based on source type
  chart = each.value.source == "local" ? each.value.chart_path : lookup(each.value, "chart", null)

  repository = each.value.source == "remote" ? lookup(each.value, "repository", null) : null
  version    = lookup(each.value, "chart_version", null)

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}
