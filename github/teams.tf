resource "github_team" "this" {
  for_each = local.teams

  name        = each.key
  description = each.value.description
  privacy     = "closed"
}

# The maintainer of both teams. (The org owner is not implicitly a team member.)
resource "github_team_membership" "maintainer" {
  for_each = local.teams

  team_id  = github_team.this[each.key].id
  username = var.maintainer
  role     = "maintainer"
}

resource "github_team_repository" "this" {
  for_each = local.repositories

  team_id    = github_team.this[each.value.team].id
  repository = github_repository.this[each.key].name
  permission = local.teams[each.value.team].permission
}

# Every other team may push branches to `catalog` and open pull requests there: a team changes its own
# file (teams/<team>.cue: the team and its apps). What it may merge is decided by catalog's CODEOWNERS
# (its file: the team; schema and everything else: the owning team) together with the default-branch
# ruleset (meta decisions.md, 2026-11-26).
resource "github_team_repository" "catalog_contributors" {
  for_each = {
    for name, _ in local.teams : name => name
    if name != local.repositories[local.catalog_repository].team
  }

  team_id    = github_team.this[each.key].id
  repository = github_repository.this[local.catalog_repository].name
  permission = "push"
}
