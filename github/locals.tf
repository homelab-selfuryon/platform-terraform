locals {
  # The catalog, shared with openbao/: teams and apps live in JSON at the repository root.
  teams = jsondecode(file("${path.module}/../teams.json"))
  apps  = jsondecode(file("${path.module}/../apps.json"))

  # Repositories that are not apps. `team` is the owning team (custom property `owner-team`),
  # `kind` is `platform` or `docs`.
  platform_repositories = {
    "meta" = {
      description = "Documentation: how the org fits together, delivery flow, decisions, security baseline"
      team        = "platform"
      kind        = "docs"
      tier        = "tier-2"
    }
    ".github" = {
      description = "Org profile, default community health files, shared Renovate preset"
      team        = "platform"
      kind        = "docs"
      tier        = "tier-2"
    }
    "platform-terraform" = {
      description = "OpenTofu for GitHub and OpenBao configuration"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-1"
    }
    "github-workflows" = {
      description = "Reusable GitHub Actions workflows: build, sign, render, publish, promote"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-1"
    }
    "platform-kit" = {
      description = "Paved road: CUE #App module and devenv module for Rust apps"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-1"
    }
    "platform-components" = {
      description = "Clusters and platform components in CUE, released as signed OCI artifacts"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-1"
    }
    "gitops" = {
      description = "What runs where: digests per cluster and environment, rendered for Flux and Argo CD"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-1"
    }
    "rust-app-template" = {
      description = "Template for a Rust app on the platform"
      team        = "platform"
      kind        = "platform"
      tier        = "tier-2"
      is_template = true
    }
  }

  # App repositories come from apps.json; a new entry creates a repository from the template.
  app_repositories = {
    for name, s in local.apps : name => {
      description = s.description
      team        = s.team
      kind        = "app"
      tier        = try(s.tier, "tier-3")
      lifecycle   = try(s.lifecycle, "active")
      app         = true
    }
  }

  repositories = merge(local.platform_repositories, local.app_repositories)

  # Template that new app repositories are created from.
  template_repository = "rust-app-template"

  # Repositories that existed before this code (import blocks); apps added later are created.
  imported_repositories = toset([
    "meta",
    ".github",
    "platform-terraform",
    "github-workflows",
    "platform-kit",
    "platform-components",
    "gitops",
    "rust-app-template",
    "notes-api",
    "notes-stats",
  ])

  # App repositories get the `staging` and `prod` GitHub Environments.
  environments = ["staging", "prod"]

  environment_pairs = {
    for pair in setproduct(keys(local.app_repositories), local.environments) :
    "${pair[0]}/${pair[1]}" => { repository = pair[0], environment = pair[1] }
  }

  tier_values      = ["tier-1", "tier-2", "tier-3"]
  lifecycle_values = ["experimental", "active", "deprecated"]
  kind_values      = ["app", "platform", "docs"]
}
