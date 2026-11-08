# platform-terraform

OpenTofu for everything outside the cluster that has an API, one root module per provider. Part of
[`homelab-selfuryon`](https://github.com/homelab-selfuryon); the reasoning is in
[`meta`](https://github.com/homelab-selfuryon/meta) (decisions, security baseline).

| Folder                          | Manages                                                                                                         | Provider                               | Applied                                    |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ------------------------------------------ |
| [`github/`](github/README.md)   | org settings, teams, the 10 repositories, custom properties, environments, rulesets, Actions policy             | `integrations/github`                  | by the owner, from a laptop                |
| [`openbao/`](openbao/README.md) | Kubernetes auth, KV v2 mount, audit device, one policy and role per app x environment, platform component roles | `hashicorp/vault` (works with OpenBao) | by the owner, over the private access path |

## Rules

- **Local state, never committed.** Each folder keeps its own `terraform.tfstate` next to the code
  (git-ignored). The state is a cache, not a source of truth: every resource that already exists has an
  `import {}` block, so a lost state is rebuilt by `tofu apply` (it adopts, it does not recreate).
  The provider lock files (`.terraform.lock.hcl`) are committed.
- **No credentials in the repository or in CI.** Tokens come from the environment. CI runs `treefmt` (tofu fmt),
  `validate`, `tflint`, actionlint and zizmor only, with `-backend=false`.
- **Always read the plan** before applying: `tofu plan -out=tfplan`, then `tofu apply tfplan`.
- Pull requests are the review; the apply happens after merge, from `main`.

## Development

```sh
devenv shell     # opentofu, tflint, gh, openbao (bao), zizmor, actionlint
treefmt --ci                     # tofu fmt, nixfmt, prettier
for d in github openbao; do tofu -chdir=$d init -backend=false && tofu -chdir=$d validate; done
for d in github openbao; do tflint --chdir=$d --config="$PWD/.tflint.hcl"; done
```

## First-time apply, in order

1. `github/` first (creates the teams the CODEOWNERS files refer to, and the rulesets). Read
   [github/README.md](github/README.md): push the initial commits of the repositories **before**
   enabling the rulesets.
2. `openbao/` after the cluster runs and OpenBao is initialised (bootstrap step 4 in
   `meta/delivery.md`).

Licensed under Apache-2.0.
