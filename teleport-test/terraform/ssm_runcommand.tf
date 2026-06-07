locals {
  ssm_run_command_documents = {
    "00-preflight" = {
      description     = "Check the bastion bootstrap context before Teleport work"
      timeout_seconds = 600
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        : "$${TELEPORT_CLUSTER_NAME:?missing TELEPORT_CLUSTER_NAME}"
        : "$${AWS_REGION:?missing AWS_REGION}"
        : "$${KUBECONFIG:?missing KUBECONFIG}"
        echo "== caller identity =="
        aws sts get-caller-identity
        echo "== eks cluster =="
        aws eks describe-cluster --name "$TELEPORT_CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.{name:name,status:status,endpoint:endpoint,private:resourcesVpcConfig.endpointPrivateAccess,public:resourcesVpcConfig.endpointPublicAccess}' --output table
        echo "== tools =="
        for bin in aws kubectl helm tsh; do
          command -v "$bin"
          "$bin" version --client 2>/dev/null || "$bin" version 2>/dev/null || true
        done
        echo "== bootstrap files =="
        ls -la /etc/teleport
      SCRIPT
      ))
    }

    "10-kubeconfig" = {
      description     = "Create the private EKS kubeconfig on the bastion"
      timeout_seconds = 900
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        mkdir -p "$(dirname "$KUBECONFIG")"
        aws eks update-kubeconfig --name "$TELEPORT_CLUSTER_NAME" --region "$AWS_REGION" --kubeconfig "$KUBECONFIG"
        chmod 0644 "$KUBECONFIG"
        for i in $(seq 1 30); do
          if KUBECONFIG="$KUBECONFIG" kubectl get nodes -o wide; then
            exit 0
          fi
          sleep 10
        done
        echo "kubectl could not reach the private EKS endpoint" >&2
        exit 1
      SCRIPT
      ))
    }

    "20-storageclass" = {
      description     = "Create a default gp3 StorageClass if the cluster has none"
      timeout_seconds = 600
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        DEFAULT_SC=$(KUBECONFIG="$KUBECONFIG" kubectl get sc -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{"\n"}{end}')
        if [ -n "$DEFAULT_SC" ]; then
          echo "default StorageClass already exists: $DEFAULT_SC"
          KUBECONFIG="$KUBECONFIG" kubectl get sc
          exit 0
        fi
        cat >/tmp/gp3-storageclass.yaml <<'EOF'
        apiVersion: storage.k8s.io/v1
        kind: StorageClass
        metadata:
          name: gp3
          annotations:
            storageclass.kubernetes.io/is-default-class: "true"
        provisioner: ebs.csi.aws.com
        parameters:
          type: gp3
          fsType: ext4
        volumeBindingMode: WaitForFirstConsumer
        allowVolumeExpansion: true
        EOF
        KUBECONFIG="$KUBECONFIG" kubectl apply -f /tmp/gp3-storageclass.yaml
        KUBECONFIG="$KUBECONFIG" kubectl get sc
      SCRIPT
      ))
    }

    "30-teleport-cluster" = {
      description     = "Install Teleport cluster and update clusterName from the service load balancer"
      timeout_seconds = 1800
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        mkdir -p "$HELM_VALUES_DIR"
        cat >"$HELM_VALUES_DIR/teleport-cluster-values.yaml" <<'EOF'
        clusterName: "teleport.example.com"
        kubeClusterName: "teleport-test"

        authentication:
          type: local

        service:
          type: LoadBalancer
        EOF
        KUBECONFIG="$KUBECONFIG" helm repo add teleport https://charts.releases.teleport.dev >/dev/null 2>&1 || true
        KUBECONFIG="$KUBECONFIG" helm repo update
        KUBECONFIG="$KUBECONFIG" helm upgrade --install teleport-cluster teleport/teleport-cluster -f "$HELM_VALUES_DIR/teleport-cluster-values.yaml"
        KUBECONFIG="$KUBECONFIG" kubectl -n default rollout status deploy/teleport-cluster-auth --timeout=10m
        PROXY_HOST=""
        for i in $(seq 1 60); do
          PROXY_HOST=$(KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
          if [ -z "$PROXY_HOST" ]; then
            PROXY_HOST=$(KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
          fi
          if [ -n "$PROXY_HOST" ]; then
            break
          fi
          sleep 10
        done
        if [ -z "$PROXY_HOST" ]; then
          echo "Teleport load balancer address was not assigned" >&2
          exit 1
        fi
        sed -i "s#^clusterName:.*#clusterName: \"$PROXY_HOST\"#" "$HELM_VALUES_DIR/teleport-cluster-values.yaml"
        KUBECONFIG="$KUBECONFIG" helm upgrade --install teleport-cluster teleport/teleport-cluster -f "$HELM_VALUES_DIR/teleport-cluster-values.yaml"
        echo "$PROXY_HOST" >/etc/teleport/proxy_host
        KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o wide
      SCRIPT
      ))
    }

    "40-teleport-agent" = {
      description     = "Install the Teleport kube/db agent after the cluster is reachable"
      timeout_seconds = 1800
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        : "$${RDS_ENDPOINT:?missing RDS_ENDPOINT}"
        mkdir -p "$HELM_VALUES_DIR"
        PROXY_HOST=$(cat /etc/teleport/proxy_host 2>/dev/null || true)
        if [ -z "$PROXY_HOST" ]; then
          PROXY_HOST=$(KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
        fi
        if [ -z "$PROXY_HOST" ]; then
          PROXY_HOST=$(KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
        fi
        if [ -z "$PROXY_HOST" ]; then
          echo "Teleport proxy host is empty" >&2
          exit 1
        fi
        PROXY_PORT=$(KUBECONFIG="$KUBECONFIG" kubectl -n default get svc teleport-cluster -o jsonpath='{range .spec.ports[?(@.name=="web")]}{.port}{"\n"}{end}' 2>/dev/null || true)
        if [ -z "$PROXY_PORT" ]; then
          PROXY_PORT=443
        fi
        KUBECONFIG="$KUBECONFIG" kubectl -n default rollout status deploy/teleport-cluster-auth --timeout=10m
        TOKEN_OUTPUT=$(KUBECONFIG="$KUBECONFIG" kubectl -n default exec deploy/teleport-cluster-auth -- tctl tokens add --type=kube,db --ttl=1h 2>/dev/null)
        TOKEN=$(printf '%s\n' "$TOKEN_OUTPUT" | awk '/invite token/ {print $NF; exit}')
        if [ -z "$TOKEN" ]; then
          echo "Teleport join token is empty" >&2
          exit 1
        fi
        STATUS_OUTPUT=$(KUBECONFIG="$KUBECONFIG" kubectl -n default exec deploy/teleport-cluster-auth -- tctl status 2>/dev/null || true)
        CA_PIN=$(printf '%s\n' "$STATUS_OUTPUT" | awk '/CA pin/ {print $NF; exit}')
        cat >"$HELM_VALUES_DIR/teleport-kube-agent-values.yaml" <<EOF
        roles: "kube,db"
        proxyAddr: "$PROXY_HOST:$PROXY_PORT"
        insecureSkipProxyTLSVerify: true

        joinParams:
          method: "token"
          tokenName: "$TOKEN"

        kubeClusterName: "$TELEPORT_CLUSTER_NAME"
        EOF
        if [ -n "$TELEPORT_AGENT_IRSA_ROLE_ARN" ]; then
          cat >>"$HELM_VALUES_DIR/teleport-kube-agent-values.yaml" <<EOF

        serviceAccount:
          name: "$TELEPORT_AGENT_SERVICE_ACCOUNT"

        annotations:
          serviceAccount:
            eks.amazonaws.com/role-arn: "$TELEPORT_AGENT_IRSA_ROLE_ARN"
        EOF
        fi
        if [ -n "$CA_PIN" ]; then
          cat >>"$HELM_VALUES_DIR/teleport-kube-agent-values.yaml" <<EOF

        caPin:
          - "$CA_PIN"
        EOF
        fi
        cat >>"$HELM_VALUES_DIR/teleport-kube-agent-values.yaml" <<EOF

        databases:
          - name: "teleport-rds"
            uri: "$RDS_ENDPOINT:$RDS_PORT"
            protocol: "postgres"
            aws:
              region: "$AWS_REGION"
            static_labels:
              env: "dev"
        EOF
        chmod 0600 "$HELM_VALUES_DIR/teleport-kube-agent-values.yaml"
        KUBECONFIG="$KUBECONFIG" helm upgrade --install teleport-agent teleport/teleport-kube-agent -f "$HELM_VALUES_DIR/teleport-kube-agent-values.yaml"
        KUBECONFIG="$KUBECONFIG" kubectl -n default rollout restart statefulset/teleport-agent
        KUBECONFIG="$KUBECONFIG" kubectl -n default delete pod teleport-agent-0 --wait=false || true
        KUBECONFIG="$KUBECONFIG" kubectl -n default rollout status statefulset/teleport-agent --timeout=10m
        KUBECONFIG="$KUBECONFIG" kubectl -n default get pods -l app=teleport-agent -o wide
      SCRIPT
      ))
    }

    "90-verify" = {
      description     = "Collect Teleport, Helm, and Kubernetes verification output"
      timeout_seconds = 600
      commands = split("\n", trimspace(<<-SCRIPT
        set -euo pipefail
        . /etc/teleport/bootstrap.env
        echo "== helm releases =="
        KUBECONFIG="$KUBECONFIG" helm list -A
        echo "== teleport pods =="
        KUBECONFIG="$KUBECONFIG" kubectl -n default get pods -o wide
        echo "== teleport services =="
        KUBECONFIG="$KUBECONFIG" kubectl -n default get svc -o wide
        echo "== storage classes =="
        KUBECONFIG="$KUBECONFIG" kubectl get sc
        echo "== generated values =="
        ls -la "$HELM_VALUES_DIR"
        sed -n '1,220p' "$HELM_VALUES_DIR/teleport-cluster-values.yaml" || true
        sed -E 's/(tokenName: ).*/\1<redacted>/' "$HELM_VALUES_DIR/teleport-kube-agent-values.yaml" || true
      SCRIPT
      ))
    }
  }
}

resource "aws_ssm_document" "teleport_run_command" {
  for_each = local.bastion_enabled ? local.ssm_run_command_documents : {}

  name            = "${local.project_name}-${each.key}"
  document_type   = "Command"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "2.2"
    description   = each.value.description
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "runShellScript"
        inputs = {
          timeoutSeconds = each.value.timeout_seconds
          runCommand     = each.value.commands
        }
      }
    ]
  })

  tags = {
    Name = "${local.project_name}-${each.key}"
  }
}
