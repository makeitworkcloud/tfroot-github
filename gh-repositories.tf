resource "github_repository" "repositories" {
  for_each           = local.github_repositories
  name               = each.key
  archived           = contains(local.archived_github_repositories, each.key)
  visibility         = contains(local.private_github_repositories, each.key) ? "private" : var.github_visibility
  auto_init          = true
  allow_squash_merge = true
  allow_merge_commit = true
  allow_rebase_merge = false
  # Auto-merge stays off except for repositories whose automation-created pull
  # requests are expected to merge themselves once required checks pass.
  allow_auto_merge            = contains(local.auto_merge_github_repositories, each.key)
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  # Topics are declared in main.tf (local.topics_by_repository) for active
  # repositories only; archived repositories are skipped and their existing
  # GitHub topics stay unmanaged. A missing entry for an active repository
  # fails the plan; use an explicit empty list for a repository that should
  # carry no topics.
  topics = contains(local.archived_github_repositories, each.key) ? null : local.topics_by_repository[each.key]
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
