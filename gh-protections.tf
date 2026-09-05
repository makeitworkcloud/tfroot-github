# Resolve the chart updater App to its GraphQL node ID. Branch protection
# allowances cannot use the App's numeric ID or bot login directly.
data "github_app" "chart_updater" {
  slug = "makeitworkbot"
}

# Strict protection requires pull requests and configured CI checks. Private
# repositories remain excluded because their GitHub plan does not enforce this
# organization policy through this resource.
resource "github_branch_protection" "protections" {
  for_each = {
    for name, repository in local.repositories : name => repository
    if !repository.archived && !repository.private && repository.protection_profile == "strict"
  }

  repository_id                   = github_repository.repositories[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = true
  allows_force_pushes             = false
  required_linear_history         = true
  require_conversation_resolution = true
  required_status_checks {
    strict   = true
    contexts = each.value.required_status_checks
  }
  # This block requires a pull request while retaining the solo-maintainer
  # workflow: zero approvals, no code-owner gate, and no bypass actors.
  required_pull_request_reviews {
    require_code_owner_reviews      = false
    required_approving_review_count = 0
    require_last_push_approval      = false
  }
  restrict_pushes {
    # Push allowances do not bypass the pull-request or required-check gates.
    # The chart updater App is added only for its kustomize-cluster destination
    # so GitHub may complete an eligible auto-merge after `test` passes.
    push_allowances = concat(
      ["${var.github_owner}/${github_team.admins.slug}"],
      each.key == "kustomize-cluster" ? [data.github_app.chart_updater.node_id] : [],
    )
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

# The relaxed profile retains pull-request-only writes and basic branch
# integrity, but does not require CI, approvals, code owners, or resolved
# conversations. Private repositories remain excluded from this resource.
resource "github_branch_protection" "relaxed_protections" {
  for_each = {
    for name, repository in local.repositories : name => repository
    if !repository.archived && !repository.private && repository.protection_profile == "relaxed"
  }

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
