# The owner's identity for later applies and for writing secrets, so the initial root token can be
# revoked. A root token is regenerated only with the recovery keys (`bao operator generate-root`).
#
# The policy covers what this module manages (mounts, auth methods, ACL policies, the Kubernetes auth
# config and roles, this token role) and the secret values under kv/. It grants nothing on seal,
# rekey, generate-root, raw storage, audit devices or other token roles.
data "vault_policy_document" "admin" {
  # Secret engines: the kv/ mount and its tuning.
  rule {
    path         = "sys/mounts"
    capabilities = ["read", "list"]
  }

  rule {
    path         = "sys/mounts/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  # Auth methods: enabling or disabling one needs sudo.
  rule {
    path         = "sys/auth"
    capabilities = ["read", "list", "sudo"]
  }

  rule {
    path         = "sys/auth/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    path         = "sys/policies/acl"
    capabilities = ["list"]
  }

  rule {
    path         = "sys/policies/acl/*"
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  rule {
    path         = "auth/kubernetes/*"
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  # Secret values: the owner puts them by hand (`bao kv put`), OpenTofu never does.
  rule {
    path         = "kv/*"
    capabilities = ["create", "read", "update", "patch", "delete", "list"]
  }

  # Its own token role, and a successor token from it (rotation without root).
  rule {
    path         = "auth/token/roles/admin"
    capabilities = ["create", "read", "update", "delete"]
  }

  rule {
    path         = "auth/token/create/admin"
    capabilities = ["update"]
  }
}

resource "vault_policy" "admin" {
  name   = "admin"
  policy = data.vault_policy_document.admin.hcl
}

# `bao token create -role=admin`: an orphan (outlives the token that created it, so revoking the root
# token does not take it along), periodic token. Unused for longer than the period, it expires; then
# a new one needs a root token from the recovery keys.
resource "vault_token_auth_backend_role" "admin" {
  role_name              = "admin"
  allowed_policies       = [vault_policy.admin.name]
  disallowed_policies    = ["root"]
  orphan                 = true
  renewable              = true
  token_period           = 30 * 24 * 3600
  token_explicit_max_ttl = 0
  token_type             = "service"
}
