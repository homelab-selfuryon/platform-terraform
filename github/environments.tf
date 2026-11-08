# GitHub Environments `staging` and `prod` on the app repositories, for identity and not as a
# gate (meta/decisions.md): the OIDC `sub` claim carries `environment:<env>`, so octo-sts issues the
# gitops token only to that workflow and environment. Deployments are limited to `v*` tags; there are
# no required reviewers (the gate is the gitops pull request).
resource "github_repository_environment" "this" {
  for_each = local.environment_pairs

  repository  = github_repository.this[each.value.repository].name
  environment = each.value.environment

  can_admins_bypass = false

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "tags" {
  for_each = local.environment_pairs

  repository  = github_repository_environment.this[each.key].repository
  environment = github_repository_environment.this[each.key].environment
  tag_pattern = "v*"
}
