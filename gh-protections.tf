# Every active repository requires a pull request with its configured CI checks
# passing before merge. The check map lives in main.tf because check-run names
# differ by repository and GitHub treats an unknown required check as pending.
resource "github_branch_protection" "protections" {
  for_each                        = toset([for repo in local.github_repositories : repo if !contains(local.archived_github_repositories, repo)])
  repository_id                   = github_repository.repositories[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = true
  allows_force_pushes             = false
  required_linear_history         = true
  require_conversation_resolution = true
  required_status_checks {
    strict   = true
    contexts = local.required_status_checks_by_repository[each.key]
  }
  # This block requires a pull request while retaining the solo-maintainer
  # workflow: zero approvals, no code-owner gate, and no bypass actors.
  required_pull_request_reviews {
    require_code_owner_reviews      = false
    required_approving_review_count = 0
    require_last_push_approval      = false
  }
  restrict_pushes {
    push_allowances = [
      "${var.github_owner}/${github_team.admins.slug}"
    ]
  }
  depends_on = [github_repository.repositories, github_team.admins, github_team_repository.admins]
}
