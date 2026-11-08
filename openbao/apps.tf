# One policy and one Kubernetes auth role per app x environment. The role is bound to the
# ServiceAccount named like the app, in the environment's namespace, and its policy grants
# read on the app's own path only.
data "vault_policy_document" "app" {
  for_each = local.app_roles

  rule {
    path         = "kv/data/${each.value.path}/*"
    capabilities = ["read"]
    description  = "Secrets of ${each.value.app} in ${each.value.env}"
  }

  rule {
    path         = "kv/metadata/${each.value.path}/*"
    capabilities = ["read", "list"]
    description  = "Secret metadata, needed by the CSI provider to resolve versions"
  }
}

resource "vault_policy" "app" {
  for_each = local.app_roles

  name   = each.key
  policy = data.vault_policy_document.app[each.key].hcl
}

resource "vault_kubernetes_auth_backend_role" "app" {
  for_each = local.app_roles

  backend   = vault_auth_backend.kubernetes.path
  role_name = each.key

  bound_service_account_names              = [each.value.app]
  bound_service_account_namespaces         = each.value.namespaces
  bound_service_account_namespace_selector = each.value.selector

  token_policies = [vault_policy.app[each.key].name]
  token_ttl      = 3600
  token_max_ttl  = 3600
  token_type     = "service"

  depends_on = [vault_kubernetes_auth_backend_config.this]
}
