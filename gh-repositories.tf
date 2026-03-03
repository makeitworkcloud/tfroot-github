/*
import {
  for_each = local.github_repositories
  to       = github_repository.repositories[each.key]
  id       = each.key
}
*/

resource "github_repository" "repositories" {
  for_each                    = local.github_repositories
  name                        = each.key
  visibility                  = var.github_visibility
  allow_squash_merge          = true
  allow_merge_commit          = true
  allow_rebase_merge          = false
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
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
