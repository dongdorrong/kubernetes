logging {
  level  = "info"
  format = "logfmt"
}

// Prometheus 스크래핑 테스트
prometheus.remote_write "prometheus_rw" {
  endpoint {
    url = "http://prometheus-server.monitoring.svc.cluster.local:9090/api/v1/write"
  }
}

prometheus.scrape "prometheus_scrape" {
  targets = [
    {"__address__" = "prometheus-server.monitoring.svc.cluster.local:9090"},
  ]
  forward_to = [prometheus.remote_write.prometheus_rw.receiver,]
}


// 로그 수집 테스트
// - 참고 : https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/
loki.write "default" {
  endpoint {
    url = "http://loki:3100/loki/api/v1/push"
  }
}

// local.file_match discovers files on the local filesystem using glob patterns and the doublestar library. It returns an array of file paths.
local.file_match "node_logs" {
  path_targets = [{
      // Monitor syslog to scrape node-logs
      __path__  = "/var/log/syslog",
      job       = "node/syslog",
      node_name = sys.env("HOSTNAME"),
      // <CLUSTER_NAME>: The label for this specific Kubernetes cluster, such as production or us-east-1.
      cluster   = "eksstudy",
  }]
}

// loki.source.file reads log entries from files and forwards them to other loki.* components.
// You can specify multiple loki.source.file components by giving them different labels.
loki.source.file "node_logs" {
  targets    = local.file_match.node_logs.targets
  forward_to = [loki.write.default.receiver]
}

// discovery.kubernetes allows you to find scrape targets from Kubernetes resources.
// It watches cluster state and ensures targets are continually synced with what is currently running in your cluster.
discovery.kubernetes "pod" {
  role = "pod"
}

// discovery.relabel rewrites the label set of the input targets by applying one or more relabeling rules.
// If no rules are defined, then the input targets are exported as-is.
discovery.relabel "pod_logs" {
  targets = discovery.kubernetes.pod.targets

  // Label creation - "namespace" field from "__meta_kubernetes_namespace"
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "replace"
    target_label = "namespace"
  }

  // Label creation - "pod" field from "__meta_kubernetes_pod_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    action = "replace"
    target_label = "pod"
  }

  // Label creation - "container" field from "__meta_kubernetes_pod_container_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "container"
  }

  // Label creation -  "app" field from "__meta_kubernetes_pod_label_app_kubernetes_io_name"
  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    action = "replace"
    target_label = "app"
  }

  // Label creation -  "job" field from "__meta_kubernetes_namespace" and "__meta_kubernetes_pod_container_name"
  // Concatenate values __meta_kubernetes_namespace/__meta_kubernetes_pod_container_name
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "job"
    separator = "/"
    replacement = "$1"
  }

  // Label creation - "container" field from "__meta_kubernetes_pod_uid" and "__meta_kubernetes_pod_container_name"
  // Concatenate values __meta_kubernetes_pod_uid/__meta_kubernetes_pod_container_name.log
  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "__path__"
    separator = "/"
    replacement = "/var/log/pods/*$1/*.log"
  }

  // Label creation -  "container_runtime" field from "__meta_kubernetes_pod_container_id"
  rule {
    source_labels = ["__meta_kubernetes_pod_container_id"]
    action = "replace"
    target_label = "container_runtime"
    regex = "^(\\S+):\\/\\/.+$"
    replacement = "$1"
  }
}

// loki.source.kubernetes tails logs from Kubernetes containers using the Kubernetes API.
loki.source.kubernetes "pod_logs" {
  targets    = discovery.relabel.pod_logs.output
  forward_to = [loki.process.pod_logs.receiver]
}

// loki.process receives log entries from other Loki components, applies one or more processing stages,
// and forwards the results to the list of receivers in the component's arguments.
loki.process "pod_logs" {
  stage.static_labels {
      values = {
        // <CLUSTER_NAME>: The label for this specific Kubernetes cluster, such as production or us-east-1.
        cluster = "eksstudy",
      }
  }

  forward_to = [loki.write.default.receiver]
}

// loki.source.kubernetes_events tails events from the Kubernetes API and converts them
// into log lines to forward to other Loki components.
loki.source.kubernetes_events "cluster_events" {
  job_name   = "integrations/kubernetes/eventhandler"
  log_format = "logfmt"
  forward_to = [
    loki.process.cluster_events.receiver,
  ]
}

// loki.process receives log entries from other loki components, applies one or more processing stages,
// and forwards the results to the list of receivers in the component's arguments.
loki.process "cluster_events" {
  forward_to = [loki.write.default.receiver]

  stage.static_labels {
    values = {
      // <CLUSTER_NAME>: The label for this specific Kubernetes cluster, such as production or us-east-1.
      cluster = "eksstudy",
    }
  }

  stage.labels {
    values = {
      kubernetes_cluster_events = "job",
    }
  }
}