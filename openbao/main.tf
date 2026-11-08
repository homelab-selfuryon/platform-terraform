# KV v2 at `kv/`: kv/<team>/<env>/<app>/<key>, kv/platform/<cluster>/<component>/<key>.
resource "vault_mount" "kv" {
  path        = "kv"
  type        = "kv"
  description = "Application and platform secrets (KV v2)"
  options = {
    version = "2"
  }
}

# Kubernetes auth, mount `kubernetes`. OpenBao runs in the cluster and reviews tokens with its own
# ServiceAccount (needs the system:auth-delegator ClusterRole, granted by platform-components).
resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Pods authenticate with their ServiceAccount token"
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend              = vault_auth_backend.kubernetes.path
  kubernetes_host      = var.kubernetes_host
  disable_local_ca_jwt = false # use the pod's own CA and token for TokenReview
}

# Audit log to stdout (collected from the pod's log stream).
resource "vault_audit" "stdout" {
  type        = "file"
  path        = "stdout"
  description = "Audit log to the container's stdout"

  options = {
    file_path = "stdout"
  }
}
