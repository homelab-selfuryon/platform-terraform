output "repositories" {
  description = "Managed repositories (HTML URLs)."
  value       = { for name, r in github_repository.this : name => r.html_url }
}

output "teams" {
  description = "Team slugs."
  value       = { for name, t in github_team.this : name => t.slug }
}
