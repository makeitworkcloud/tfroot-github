/*
import {
  for_each = local.github_repositories
  to       = github_branch_protection.protections[each.key]
  id       = "${each.key}:main"
}
*/

resource "github_branch_protection" "protections" {
  for_each                        = toset([for repo in local.github_repositories : repo if !contains(local.archived_github_repositories, repo)])
  repository_id                   = github_repository.repositories[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = false
  allows_force_pushes             = false
  required_linear_history         = true
  require_conversation_resolution = true
  required_status_checks {
    strict   = true
    contexts = []
  }
  required_pull_request_reviews {
    dismissal_restrictions          = ["${var.github_owner}/${github_team.admins.slug}"]
    dismiss_stale_reviews           = true
    pull_request_bypassers          = ["${var.github_owner}/${github_team.admins.slug}"]
    require_code_owner_reviews      = true
    required_approving_review_count = 0
    require_last_push_approval      = true
    restrict_dismissals             = true
  }
  restrict_pushes {
    push_allowances = [
      "${var.github_owner}/${github_team.admins.slug}"
    ]
  }
  depends_on = [github_repository.repositories, github_team.admins]
}
