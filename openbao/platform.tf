# Roles for platform components that need a secret (DNS provider token for cert-manager and
# external-dns, synced to a Kubernetes Secret by the CSI driver in a `*-system` namespace).
data "vault_policy_document" "platform" {
  for_each = local.platform_roles

  rule {
    path         = "kv/data/${each.value.path}/*"
    capabilities = ["read"]
  }

  rule {
    path         = "kv/metadata/${each.value.path}/*"
    capabilities = ["read", "list"]
  }
}

resource "vault_policy" "platform" {
  for_each = local.platform_roles

  name   = each.key
  policy = data.vault_policy_document.platform[each.key].hcl
}

resource "vault_kubernetes_auth_backend_role" "platform" {
  for_each = local.platform_roles

  backend   = vault_auth_backend.kubernetes.path
  role_name = each.key

  bound_service_account_names      = [each.value.service_account]
  bound_service_account_namespaces = [each.value.namespace]

  token_policies = [vault_policy.platform[each.key].name]
  token_ttl      = 3600
  token_max_ttl  = 3600
  token_type     = "service"

  depends_on = [vault_kubernetes_auth_backend_config.this]
}
