# Organization settings. Base permission and "members can't create repositories" were set by hand
# once (see meta/org.md); this resource brings them under code.
#
# GitHub Free: the `advanced_security_*` setting is not available and left out. The *_for_new_repositories
# settings below still work through this API; GitHub is moving them to "code security configurations",
# which this provider version does not manage (see README.md).
resource "github_organization_settings" "this" {
  billing_email = var.billing_email
  name          = "Homelab"
  location      = "" # not published
  description   = "Platform engineering showcase: Kubernetes with CUE and secure defaults"

  default_repository_permission            = "none"
  members_can_create_repositories          = false
  members_can_create_public_repositories   = false
  members_can_create_private_repositories  = false
  members_can_create_internal_repositories = false
  members_can_create_pages                 = false
  members_can_create_public_pages          = false
  members_can_create_private_pages         = false
  members_can_fork_private_repositories    = false
  web_commit_signoff_required              = false # commits are signed (rulesets); no DCO sign-off

  dependency_graph_enabled_for_new_repositories                = true
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}
