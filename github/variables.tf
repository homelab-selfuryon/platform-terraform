variable "owner" {
  description = "GitHub organization that is managed."
  type        = string
  default     = "homelab-selfuryon"
}

variable "billing_email" {
  description = "Billing e-mail of the organization (required by the provider; never committed). Set with TF_VAR_billing_email."
  type        = string
  sensitive   = true
}

variable "maintainer" {
  description = "GitHub login of the person who maintains both teams."
  type        = string
  default     = "selfuryon"
}

variable "ruleset_enforcement" {
  description = "Enforcement of the repository rulesets: active, evaluate (log only) or disabled. Use `disabled` or `evaluate` until the initial commits have been pushed to the new repositories."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["active", "evaluate", "disabled"], var.ruleset_enforcement)
    error_message = "ruleset_enforcement must be active, evaluate or disabled."
  }
}

variable "ruleset_admin_bypass" {
  description = <<-EOT
    Let repository admins bypass the default-branch ruleset **through a pull request only** (never a
    direct push). With one maintainer this is what makes merging possible: the code-owner review is
    required and the author cannot approve their own pull request. Set to false once a second
    maintainer exists.
  EOT
  type        = bool
  default     = true
}

variable "ruleset_bypass_integrations" {
  description = <<-EOT
    GitHub App installations (name => app ID) that may bypass the default-branch ruleset through a pull
    request, e.g. the Renovate app, so that its automerge works despite the code-owner review rule.
    Empty by default: Renovate PRs then wait for a platform review.
  EOT
  type        = map(number)
  default     = {}
}

variable "required_status_checks" {
  description = "Required status check contexts on the default branch, per repository. Repositories not listed get `default_required_checks`."
  type        = map(list(string))
  default     = {}
}

variable "default_required_checks" {
  description = "Status checks required on the default branch of every repository without an entry in required_status_checks."
  type        = list(string)
  default     = ["final-check"]
}

variable "allowed_action_patterns" {
  description = <<-EOT
    Third-party actions and reusable workflows allowed in addition to GitHub's own (`actions/*`,
    `github/*`). Every action must additionally be pinned by commit SHA (enforced by the org policy).
  EOT
  type        = list(string)
  default = [
    # The org's own actions and reusable workflows.
    "homelab-selfuryon/*",
    # Nix and devenv on the runner.
    "cachix/install-nix-action@*",
    "cachix/cachix-action@*",
    "nixbuild/nix-quick-install-action@*",
    # Images and artifacts.
    "docker/setup-buildx-action@*",
    "docker/build-push-action@*",
    "docker/login-action@*",
    "oras-project/setup-oras@*",
    # Supply chain.
    "sigstore/cosign-installer@*",
    "octo-sts/action@*",
    # Release and automation.
    "googleapis/release-please-action@*",
    "peter-evans/create-pull-request@*",
    "int128/diff-action@*",
    "int128/comment-action@*",
  ]
}
