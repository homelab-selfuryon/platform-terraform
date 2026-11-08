# OpenBao speaks the Vault API, so the HashiCorp Vault provider is used (see README.md).
#
# Address and token come from the environment, not from code:
#   export VAULT_ADDR=https://<private address of OpenBao>
#   export VAULT_TOKEN=<token with the needed policy; root token only for the first apply>
# (`BAO_ADDR` / `BAO_TOKEN` are read by the `bao` CLI, not by this provider.)
provider "vault" {
  # Do not mint a child token for the run: the provider would otherwise need `auth/token/create`
  # and leave an extra token behind.
  skip_child_token = true
}
