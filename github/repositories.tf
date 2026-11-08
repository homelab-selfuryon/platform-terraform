resource "github_repository" "this" {
  for_each = local.repositories

  name         = each.key
  description  = each.value.description
  visibility   = "public"
  is_template  = try(each.value.is_template, false)
  homepage_url = null

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "BLANK"
  allow_auto_merge            = true # gitops release PRs and Renovate use auto-merge
  allow_update_branch         = true
  delete_branch_on_merge      = true

  web_commit_signoff_required = false
  archive_on_destroy          = true

  # Public repositories: secret scanning is free. Advanced Security is implicit and not settable.
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  # New app repositories are generated from the template. The template block is create-time only:
  # ignoring it keeps the imported repositories (which were not generated from it) from being replaced.
  dynamic "template" {
    for_each = try(each.value.app, false) ? [1] : []
    content {
      owner      = var.owner
      repository = local.template_repository
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [template]
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  for_each = local.repositories

  repository = github_repository.this[each.key].name
  enabled    = true
}
