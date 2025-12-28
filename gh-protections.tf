/*
import {
  for_each = local.github_repositories
  to       = github_branch_protection.protections[each.key]
  id       = "${each.key}:main"
}
*/

resource "github_branch_protection" "protections" {
  for_each                        = local.github_repositories
  repository_id                   = github_repository.repositories[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = false
  allows_force_pushes             = true
  required_linear_history         = true
  require_conversation_resolution = true
  required_status_checks {
    strict   = true
    contexts = []
  }
  required_pull_request_reviews {
    dismissal_restrictions          = ["/${github_team.admins.slug}"]
    dismiss_stale_reviews           = true
    pull_request_bypassers          = ["/${github_team.admins.slug}"]
    require_code_owner_reviews      = true
    required_approving_review_count = 1
    require_last_push_approval      = true
    restrict_dismissals             = true
  }
  restrict_pushes {
    push_allowances = [
      "/${github_team.admins.slug}"
    ]
  }
  depends_on = [github_repository.repositories, github_team.admins]
}
