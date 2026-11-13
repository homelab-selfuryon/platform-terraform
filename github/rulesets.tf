# Repository rulesets. GitHub Free has no organization-level rulesets (the endpoint answers 404), so
# the same two rulesets are created in every repository. Rulesets are free for public repositories.

# Default branch: pull request with code-owner review (none with solo_maintainer), signed commits,
# linear history, no force-push or deletion, required status checks.
resource "github_repository_ruleset" "default_branch" {
  for_each = local.repositories

  repository  = github_repository.this[each.key].name
  name        = "default-branch"
  target      = "branch"
  enforcement = var.ruleset_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = var.ruleset_admin_bypass ? [1] : []
    content {
      actor_type  = "RepositoryRole"
      actor_id    = 5 # the built-in "admin" role
      bypass_mode = "pull_request"
    }
  }

  dynamic "bypass_actors" {
    for_each = var.ruleset_bypass_integrations
    content {
      actor_type  = "Integration"
      actor_id    = bypass_actors.value
      bypass_mode = "pull_request"
    }
  }

  rules {
    creation                = false
    update                  = false
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    required_signatures     = true

    pull_request {
      required_approving_review_count   = 0
      require_code_owner_review         = !var.solo_maintainer
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["squash"]
    }

    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = true

      dynamic "required_check" {
        for_each = lookup(var.required_status_checks, each.key, var.default_required_checks)
        content {
          context = required_check.value
        }
      }
    }
  }
}

# Tags `v*` are immutable: they can be created (by release-please) but never moved or deleted. Tags
# are the release identity that signatures and the gitops digests refer to.
resource "github_repository_ruleset" "release_tags" {
  for_each = local.repositories

  repository  = github_repository.this[each.key].name
  name        = "release-tags"
  target      = "tag"
  enforcement = var.ruleset_enforcement

  conditions {
    ref_name {
      include = ["refs/tags/v*"]
      exclude = []
    }
  }

  rules {
    update           = true
    deletion         = true
    non_fast_forward = true
  }
}
