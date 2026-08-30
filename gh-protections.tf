# Every active public repository requires a pull request with its configured CI
# checks passing before merge, except repositories explicitly assigned the
# relaxed protection profile below. Private repositories are deliberately
# excluded: GitHub Free cannot enforce these protections there, and personal
# private repositories are outside the organization's review policy. The check
# map lives in main.tf because check-run names differ by repository and GitHub
# treats an unknown required check as pending.
resource "github_branch_protection" "protections" {
  for_each = toset([
    for repo in local.github_repositories : repo
    if !contains(local.archived_github_repositories, repo) && !contains(local.private_github_repositories, repo) && !contains(local.relaxed_branch_protection_github_repositories, repo)
  ])

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
  # Seed centrally managed files before protecting a newly added repository's
  # main branch. Without this ordering, GitHub can reject the file commits as
  # soon as the required-check rule is created in the same apply.
  depends_on = [
    github_repository.repositories,
    github_repository_file.dependabot,
    github_repository_file.dependabot_notify,
    github_team.admins,
    github_team_repository.admins,
  ]
}

# The relaxed profile is for public personal repositories: pull-request-only
# writes and basic branch integrity, while allowing any pull request to merge
# without a CI, approval, code-owner, or conversation-resolution gate. Private
# repositories are deliberately excluded from all branch-protection resources.
resource "github_branch_protection" "relaxed_protections" {
  for_each = toset([
    for repo in local.relaxed_branch_protection_github_repositories : repo
    if !contains(local.archived_github_repositories, repo) && !contains(local.private_github_repositories, repo)
  ])

  repository_id           = github_repository.repositories[each.key].node_id
  pattern                 = "main"
  enforce_admins          = true
  allows_force_pushes     = false
  required_linear_history = true
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
  depends_on = [
    github_repository.repositories,
    github_team.admins,
    github_team_repository.admins,
  ]
}
