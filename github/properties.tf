# Custom properties: schema at the organization level, values per repository. The properties let
# policy and dashboards select repositories by tier or owner instead of by name.
resource "github_organization_custom_properties" "tier" {
  property_name  = "tier"
  value_type     = "single_select"
  description    = "How much the organization depends on this repository. tier-1: delivery trust anchors."
  allowed_values = local.tier_values
  required       = false
}

resource "github_organization_custom_properties" "owner_team" {
  property_name  = "owner-team"
  value_type     = "single_select"
  description    = "Team that owns the repository."
  allowed_values = keys(local.teams)
  required       = false
}

resource "github_organization_custom_properties" "lifecycle" {
  property_name  = "lifecycle"
  value_type     = "single_select"
  description    = "Lifecycle stage of the repository."
  allowed_values = local.lifecycle_values
  required       = false
}

resource "github_repository_custom_property" "tier" {
  for_each = local.repositories

  repository     = github_repository.this[each.key].name
  property_name  = github_organization_custom_properties.tier.property_name
  property_type  = "single_select"
  property_value = [each.value.tier]
}

resource "github_repository_custom_property" "owner_team" {
  for_each = local.repositories

  repository     = github_repository.this[each.key].name
  property_name  = github_organization_custom_properties.owner_team.property_name
  property_type  = "single_select"
  property_value = [each.value.team]
}

resource "github_repository_custom_property" "lifecycle" {
  for_each = local.repositories

  repository     = github_repository.this[each.key].name
  property_name  = github_organization_custom_properties.lifecycle.property_name
  property_type  = "single_select"
  property_value = [try(each.value.lifecycle, "active")]
}

resource "github_organization_custom_properties" "kind" {
  property_name  = "kind"
  value_type     = "single_select"
  description    = "What the repository is: an app, a platform repository, or documentation."
  allowed_values = local.kind_values
  required       = false
}

resource "github_repository_custom_property" "kind" {
  for_each = local.repositories

  repository     = github_repository.this[each.key].name
  property_name  = github_organization_custom_properties.kind.property_name
  property_type  = "single_select"
  property_value = [each.value.kind]
}
