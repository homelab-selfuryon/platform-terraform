# Actions policy for the whole organization: GitHub's own actions plus an explicit allowlist, every
# action pinned by commit SHA, read-only default token, Actions cannot approve pull requests. The same
# switch keeps GITHUB_TOKEN from creating pull requests: bots open them with octo-sts tokens.
resource "github_actions_organization_permissions" "this" {
  enabled_repositories = "all"
  allowed_actions      = "selected"
  sha_pinning_required = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed     = var.allowed_action_patterns
  }
}

resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = var.owner
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}
