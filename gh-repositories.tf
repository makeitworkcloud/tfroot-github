/*
import {
  for_each = local.github_repositories
  to       = github_repository.repositories[each.key]
  id       = each.key
}
*/

resource "github_repository" "repositories" {
  for_each   = local.github_repositories
  name       = each.key
  visibility = var.github_visibility
  lifecycle {
    ignore_changes = [
      description,
      has_downloads,
      has_issues,
      has_projects,
      has_wiki,
      homepage_url,
      vulnerability_alerts
    ]
  }
}
