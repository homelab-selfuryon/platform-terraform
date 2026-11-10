# openbao/

OpenBao configuration as code: Kubernetes auth, the `kv/` mount, and one policy +
role per app x environment and per platform component.

## Provider choice

`hashicorp/vault` v5. OpenBao keeps the Vault API for these paths, and the OpenBao documentation
points to the Vault provider. No OpenBao-specific Terraform provider exists on the OpenTofu or
Terraform registry (checked 2026-11-07; there is no `openbao/terraform-provider-openbao` repository). The
provider licence (MPL) is not a problem. Caveat: Vault Enterprise-only features (namespaces,
Sentinel) must not be used; `namespace` is left unset.

## What it creates

| Resource                | Value                                                                                                                                                                                                                                                                                                                       |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| KV v2 mount             | `kv/` (`kv/<team>/<env>/<app>/<key>`, `kv/platform/<cluster>/<component>/<key>`)                                                                                                                                                                                                                                            |
| Auth mount              | `kubernetes`; config uses the pod's own CA and ServiceAccount token for TokenReview (OpenBao runs in the cluster, `kubernetes_host = https://kubernetes.default.svc`)                                                                                                                                                       |
| Admin                   | policy `admin` + token role `admin` (orphan, periodic 30 days): the owner's token for applies and `bao kv put`; no seal, rekey, generate-root, raw or audit rights                                                                                                                                                          |
| Audit device            | none here: OpenBao enables audit devices only from its server config (`audit "file" "stdout"` in platform-components)                                                                                                                                                                                                       |
| App roles/policies      | `<team>-<env>-<app>` for notes-api and notes-stats x `preview`, `staging`, `prod`; the policy reads `kv/data/<team>/<env>/<app>/*` (+ metadata) only                                                                                                                                                                        |
| Platform roles/policies | `platform-alpha-01-cert-manager` (SA `secret-sync` in `cert-manager-system`), `platform-alpha-01-external-dns` (SA `external-dns` in `external-dns-system`); policy reads `kv/data/platform/alpha-01/<component>` (the path itself, key `api-token`). Names and ServiceAccounts: variables `cluster`, `platform_components` |

Service roles bind the ServiceAccount **named like the service** to the namespace `<team>-<env>`.

### Preview namespaces

OpenBao's Kubernetes auth supports only exact namespace names or `*`; there is **no glob** such as
`notes-pr-*`. It does support `bound_service_account_namespace_selector`, a Kubernetes label selector.
The `preview` roles therefore select on the labels `homelab-selfuryon.github.io/team=<team>` and
`homelab-selfuryon.github.io/env=preview` instead of a name, written as a LabelSelector in JSON
(`{"matchLabels": {...}}`; OpenBao rejects the `k=v,k=v` string form).
Requirements on the cluster side (to be provided by `platform-components`):

1. The Argo-created preview namespaces `<team>-pr-<n>` carry the labels `homelab-selfuryon.github.io/team=<team>`
   and `homelab-selfuryon.github.io/env=preview`, set by the platform (the ApplicationSet's
   `managedNamespaceMetadata`, or a Kyverno mutation), never by the tenant.
2. The ServiceAccount OpenBao uses for TokenReview needs `get`, `list` on `namespaces` in addition to
   `system:auth-delegator`.

Because the selector is a label, a tenant that could label its own namespace could widen the match:
tenants must not be able to patch namespace labels (they cannot, and the Kyverno policies keep it so).

## Apply procedure

OpenBao is not reachable from the internet; apply over the private access path, after the cluster is
up and OpenBao is initialised and unsealed (bootstrap step 4, `meta/delivery.md`).

```sh
cd platform-terraform/openbao
export VAULT_ADDR=https://<private address of OpenBao>   # the provider reads VAULT_*, the bao CLI BAO_*
export VAULT_TOKEN=<token>                                 # the admin token; the root token only for the first apply
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

The first apply needs the initial root token (it creates the mounts, auth method and policies, and
the `admin` policy and token role). Then switch to an admin token and revoke the root token:

```sh
umask 077
VAULT_TOKEN=<root token> bao token create -role=admin -display-name=owner -field=token > <bundle>/admin-token
VAULT_TOKEN=$(cat <bundle>/admin-token) tofu plan     # empty: the admin token can manage everything here
VAULT_TOKEN=<root token> bao token revoke -self
```

The admin token is periodic: each use within 30 days may renew it (`bao token renew`), unused for
longer it expires. Rotate it with `bao token create -role=admin` from the current one, then revoke the
old one. When no admin token is left: `bao operator generate-root` with the recovery keys, create a
new admin token, revoke that root token.

Check: `bao read auth/kubernetes/role/notes-prod-notes-api`.

There are no `import {}` blocks: nothing exists in OpenBao before the first apply. After a lost state,
import with `tofu import vault_mount.kv kv`, `vault_auth_backend.kubernetes kubernetes`,
`vault_kubernetes_auth_backend_config.this auth/kubernetes/config`,
`'vault_policy.app["<role>"]' <role>`,
`'vault_kubernetes_auth_backend_role.app["<role>"]' auth/kubernetes/role/<role>` (same for
`platform`).

## Adding an app

Add it to `../apps.json` (the same catalog `github/` uses), apply. The secret values are put by
the owner, never by OpenTofu: `bao kv put kv/notes/prod/notes-api/example-key value=...`.
