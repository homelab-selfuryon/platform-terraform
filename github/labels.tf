# Label `preview` on the app repositories and the template, managed here so every app (also one
# created later from the template) has it: a pull request with it gets a preview environment
# (the app's preview.yaml builds it, the gitops ApplicationSet only takes labelled PRs).
resource "github_issue_label" "preview" {
  for_each = toset(concat(keys(local.app_repositories), [local.template_repository]))

  repository  = github_repository.this[each.value].name
  name        = "preview"
  color       = "1d76db"
  description = "Deploy a preview environment <team>-pr-<n> for this pull request"
}
