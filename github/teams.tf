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
