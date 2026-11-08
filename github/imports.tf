# Everything that already exists is imported, so `tofu apply` on a fresh checkout (or after losing
# the local state) adopts it instead of failing. Teams, rulesets, environments, custom properties and
# the Actions policy did not exist when this was written: no import blocks for them.

import {
  to = github_organization_settings.this
  id = "353728095" # numeric ID of the organization: gh api orgs/homelab-selfuryon -q .id
}

import {
  for_each = local.imported_repositories
  to       = github_repository.this[each.key]
  id       = each.key
}

import {
  for_each = local.imported_repositories
  to       = github_repository_vulnerability_alerts.this[each.key]
  id       = each.key
}
