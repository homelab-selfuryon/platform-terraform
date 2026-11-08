locals {
  # Apps that use secrets: the catalog in apps.json (shared with github/). Add an app there
  # to give it roles and policies.
  apps = {
    for name, s in jsondecode(file("${path.module}/../apps.json")) : name => {
      team = s.team
      envs = try(s.envs, ["preview", "staging", "prod"])
    }
  }

  # One entry per app x environment. Role and policy are named `<team>-<env>-<app>` and may read
  # only `kv/<team>/<env>/<app>/*`. (delivery.md, "Cluster-side names")
  app_roles = merge([
    for app, s in local.apps : {
      for env in s.envs :
      "${s.team}-${env}-${app}" => {
        app  = app
        team = s.team
        env  = env
        path = "${s.team}/${env}/${app}"
        # staging and prod live in `<team>-<env>`. Preview namespaces are `<team>-pr-<n>` and appear
        # and disappear per pull request, so they are selected by label (OpenBao has no glob on
        # namespace names).
        namespaces = env == "preview" ? null : ["${s.team}-${env}"]
        selector = env == "preview" ? join(",", [
          "${var.label_prefix}team=${s.team}",
          "${var.label_prefix}env=preview",
        ]) : null
      }
    }
  ]...)

  platform_roles = {
    for name, c in var.platform_components :
    "platform-${var.cluster}-${name}" => {
      service_account = c.service_account
      namespace       = c.namespace
      path            = "platform/${var.cluster}/${name}"
    }
  }
}
