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

# No audit device here: OpenBao enables audit devices only from its server configuration (the `audit`
# stanza in platform-components, components/security/openbao), not through the API.
