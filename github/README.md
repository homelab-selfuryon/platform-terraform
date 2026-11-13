# github/

The GitHub organization `homelab-selfuryon` as code: `integrations/github` provider 6.x, owner
`homelab-selfuryon`, token from the environment.

## What it manages

| File                           | Resources                                                                                                                                                                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `org.tf`                       | Organization settings: base permission `none`, members can't create repositories, web commit sign-off required, dependency graph / Dependabot / secret scanning (+ push protection) for new repositories                 |
| `repositories.tf`, `locals.tf` | The 10 repositories (public, wiki off, squash-only with PR title, auto-merge allowed, delete branch on merge, secret scanning + push protection, vulnerability alerts, `rust-app-template` is a template)                |
| `teams.tf`                     | Teams `platform` and `notes` (maintainer `selfuryon`); `platform` is admin on the platform repositories, `notes` maintains `notes-api` and `notes-stats`                                                                 |
| `properties.tf`                | Custom properties `kind`, `tier`, `owner-team`, `lifecycle` (schema + value per repository)                                                                                                                              |
| `environments.tf`              | Environments `staging` and `prod` on `notes-api` and `notes-stats`, deployment policy: custom tag pattern `v*`, no reviewers                                                                                             |
| `rulesets.tf`                  | Per repository: `default-branch` (PR, code-owner review, 0 extra approvals, signed commits, linear history, no force-push or deletion, required check `final-check`) and `release-tags` (`v*` can't be moved or deleted) |
| `actions.tf`                   | Org Actions policy: GitHub-owned + allowlist, SHA pinning required, read-only `GITHUB_TOKEN`, Actions can't approve PRs                                                                                                  |
| `imports.tf`                   | `import {}` for the org settings, the 10 repositories and their vulnerability alerts                                                                                                                                     |

Teams, custom properties, environments, rulesets and the Actions policy did not exist when this was
written: they have no import blocks and are created by the first apply.

## What GitHub Free allows (checked 2026-11-07)

| Feature                                                          | On Free with public repositories                                       | Used here                                                                                               |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Org-level rulesets                                               | **No** (`GET /orgs/{org}/rulesets` answers 404; they need a paid plan) | Repository rulesets, the same two in every repository (`for_each`)                                      |
| Repository rulesets                                              | Yes, public repositories                                               | Yes                                                                                                     |
| Custom properties (org schema + values)                          | Yes (the schema endpoint answers)                                      | Yes                                                                                                     |
| Required workflows                                               | **No** (part of org rulesets)                                          | Not used; every repository calls `lint-workflows` / its CI itself and `final-check` is a required check |
| Environments with deployment branch/tag policy                   | Yes, public repositories                                               | Yes                                                                                                     |
| Environment required reviewers                                   | Yes for public repositories                                            | Deliberately unused                                                                                     |
| Org Actions policy (allowed actions, workflow token permissions) | Yes                                                                    | Yes                                                                                                     |
| Org-wide "code security configurations"                          | Only for paid plans / not managed by this provider version             | The legacy `*_for_new_repositories` settings are used; per-repository settings are managed explicitly   |
| Private vulnerability reporting                                  | Yes                                                                    | **Not manageable** by the provider: one-line `gh api` command below                                     |
| 2FA requirement                                                  | Setting exists, **not settable via the API**                           | Enable in the UI                                                                                        |
| Org-level secret scanning default                                | yes                                                                    | Yes                                                                                                     |
| Adding custom properties to the Actions OIDC token               | Not exposed by the provider                                            | Not done                                                                                                |

## Settings the provider cannot manage

```sh
# Private vulnerability reporting (SECURITY.md depends on it), once per repository, and for new ones:
for r in $(gh repo list homelab-selfuryon --json name -q '.[].name'); do
  gh api -X PUT "repos/homelab-selfuryon/$r/private-vulnerability-reporting"
done
# Fork pull request workflows: require approval for all outside collaborators:
gh api -X PUT orgs/homelab-selfuryon/actions/permissions/fork-pr-contributor-approval \
  -f approval_policy=all_external_contributors
```

And in the UI (no API, no provider resource):

- Settings -> Authentication security -> require two-factor authentication.
- Settings -> Packages -> Package creation: allow **Public** (every artifact the clusters pull, and
  the CUE modules, are public packages). Then make each new package public once, after its first
  publish.

## Apply procedure

Prerequisites: `devenv shell` (or direnv), `gh auth login` as the org owner, and a token with scopes
`repo` and `admin:org` (`gh auth refresh -s admin:org`). The billing e-mail is required by the
provider and never committed.

```sh
cd platform-terraform/github
export GITHUB_TOKEN=$(gh auth token)
export TF_VAR_billing_email='<billing e-mail of the organization>'   # not stored anywhere

tofu init
tofu plan -out=tfplan
```

Read the plan. Expected on the first run:

- **imports**: the org settings, 10 repositories, 10 vulnerability-alert resources;
- **updates in place** to the imported repositories: squash-only, PR title as message, auto-merge,
  delete branch on merge, wiki off, projects off, secret scanning + push protection, sign-off,
  `rust-app-template` becomes a template;
- **creates**: teams, memberships, team access, custom properties, environments + deployment policies,
  rulesets, Actions policy.

Nothing is destroyed (repositories carry `prevent_destroy`). Then:

```sh
tofu apply tfplan
```

### Rulesets and the first commits

The repositories exist but are empty, and the default-branch ruleset blocks direct pushes. Either
push the initial commit of every repository **before** the first apply, or apply once with
`TF_VAR_ruleset_enforcement=disabled`, push, and apply again without it (`evaluate` logs violations
without blocking).

### Solo maintainer (an exception of this homelab)

GitHub never lets the author of a pull request approve it, so with one maintainer a required
code-owner review can only be met by bypassing the ruleset. This organization therefore sets
`solo_maintainer = true` in the committed `homelab.auto.tfvars`: the default-branch ruleset requires
no review. Everything else stays: changes only through pull requests, signed commits, linear history,
the required check `final-check`, resolved review threads; no admin bypass
(`ruleset_admin_bypass = false`), so the checks bind the maintainer too. Renovate's automerge works
again without a bypass for its app: it still waits for the required checks.

**A real organization does not copy this.** It keeps the defaults (`solo_maintainer = false`,
`ruleset_admin_bypass = false`): every change is approved by a code owner other than its author.
Delete `homelab.auto.tfvars` (or set both to false) as soon as there is a second maintainer
(`meta/decisions.md`, 2026-11-13).

### Required check `final-check`

Every repository's CI must have a job named `final-check` that aggregates the others (this repository
and `.github` do). A repository that uses another name sets it in `required_status_checks`.

### Lost state

Delete `terraform.tfstate*` and run the procedure again: the import blocks adopt the organization
settings and repositories. Resources without an import block (teams, rulesets, environments,
properties, Actions policy) would then fail with "already exists": import them with
`tofu import` (ids: team slug; ruleset `<repo>:<ruleset id>`; environment `<repo>:<env>`;
property `<name>`; Actions permissions `homelab-selfuryon`) or delete them in the UI first.

## Variables

| Variable                                            | Default             | Meaning                                                    |
| --------------------------------------------------- | ------------------- | ---------------------------------------------------------- |
| `billing_email`                                     | required, sensitive | Org billing e-mail (`TF_VAR_billing_email`)                |
| `ruleset_enforcement`                               | `active`            | `active`, `evaluate`, `disabled`                           |
| `solo_maintainer`                                   | `false`             | No required review (this org: `true`, homelab.auto.tfvars) |
| `ruleset_admin_bypass`                              | `false`             | Admin bypass through a pull request (emergency only)       |
| `ruleset_bypass_integrations`                       | `{}`                | GitHub App name => ID that may bypass via pull request     |
| `required_status_checks`, `default_required_checks` | `["final-check"]`   | Required checks per repository                             |
| `allowed_action_patterns`                           | see `variables.tf`  | Third-party actions allowed by the org policy              |
| `maintainer`                                        | `selfuryon`         | Maintainer of both teams                                   |

## Catalog: adding an app or a team

`../apps.json` and `../teams.json` are read by this folder and by `openbao/`. A new entry in
`apps.json` (`team`, `description`, optional `tier`, `lifecycle`, `envs`) creates, from the catalog
alone: the repository **generated from `rust-app-template`**, custom properties (`kind=app`,
`owner-team`, `tier`, `lifecycle`), team access, the `staging`/`prod` environments (tags `v*`), both
rulesets, and (in `openbao/`) the roles and policies. A new team: `teams.json` (`description`,
`permission`) plus `platform-components` `teams/<team>.cue`.

- The `template` block only matters at creation; it is under `ignore_changes`, so `notes-api` and
  `notes-stats` (imported, not generated from the template) are not replaced. A new app needs the
  template repository to be a template already: apply once with the template flag set before adding
  apps in the same run.
- Repositories that existed before this code are listed in `local.imported_repositories`
  (`locals.tf`); only those get import blocks. A new app is created, not imported.
- Platform and docs repositories (`kind=platform` / `docs`) are listed in `local.platform_repositories`.

## OIDC token: `owner-team` and `kind`

The provider (6.13) has no resource for OIDC custom property inclusions (only the subject claim
template). One-time step after the first apply (organization endpoint, public preview, API version
`2026-03-10`; not run by this code):

```sh
for p in owner-team kind; do
  gh api -X POST orgs/homelab-selfuryon/actions/oidc/customization/properties/repo \
    -H "X-GitHub-Api-Version: 2026-03-10" -f custom_property_name="$p"
done
# check; the tokens then carry repo_property_owner_team and repo_property_kind:
gh api orgs/homelab-selfuryon/actions/oidc/customization/properties/repo -H "X-GitHub-Api-Version: 2026-03-10"
# remove: gh api -X DELETE orgs/homelab-selfuryon/actions/oidc/customization/properties/repo/<name> -H ...
```
