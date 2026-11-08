output "app_roles" {
  description = "Kubernetes auth roles for apps, with the path each may read."
  value       = { for name, r in local.app_roles : name => "kv/${r.path}/*" }
}

output "platform_roles" {
  description = "Kubernetes auth roles for platform components, with the path each may read."
  value       = { for name, r in local.platform_roles : name => "kv/${r.path}/*" }
}
