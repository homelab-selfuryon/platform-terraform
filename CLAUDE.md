# platform-terraform

OpenTofu, one root module per provider: `github/` (org, repositories, teams, rulesets, environments,
Actions policy) and `openbao/` (Kubernetes auth, `kv/`, per-app policies and roles). Local state,
git-ignored; every existing resource has an `import {}` block. The owner applies by hand; CI never has
credentials.

## Layout

- `github/` — `apps.json` and `teams.json` (repository root, shared with `openbao/`) hold apps and teams; platform repositories are in `locals.tf`: edit data there, not in the
  resources. `imports.tf` imports what exists. See `github/README.md`.
- `openbao/` — apps come from `../apps.json`; `locals.tf` has the role naming
  (`<team>-<env>-<app>`, `platform-<cluster>-<component>`) from `meta/delivery.md`. See `openbao/README.md`.
- `.tflint.hcl`, `devenv.nix`, `devenv.yaml`, `.github/workflows/ci.yaml` (job `final-check` is the required check).

## Commands

```sh
devenv shell -- treefmt --ci
devenv shell -- sh -c 'for d in github openbao; do tofu -chdir=$d init -backend=false && tofu -chdir=$d validate; done'
devenv shell -- sh -c 'for d in github openbao; do tflint --chdir=$d --config=$PWD/.tflint.hcl; done'
devenv shell -- actionlint; devenv shell -- zizmor .github/workflows
```

Never run `tofu plan`/`apply` without the owner's go-ahead: it talks to live GitHub or OpenBao.

## Conventions

- Conventional Commits (`!` for breaking), signed commits.
- No secrets, tokens, e-mail addresses or state in git. Tokens come from `GITHUB_TOKEN` / `VAULT_TOKEN`.
- GitHub Free: no org-level rulesets, so repository rulesets via `for_each` (see `github/README.md`).
- Names (teams, roles, paths, namespaces) must match `meta/delivery.md`; change both together.
- Commit `.terraform.lock.hcl`; never commit `*.tfstate*`.
