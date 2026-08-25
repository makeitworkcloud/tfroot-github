resource "github_membership" "admin" {
  username = "xnoto"
  role     = "admin"
}

resource "github_team" "admins" {
  name        = "admins"
  description = "Administrators — ArgoCD admins and GitHub branch-protection bypass actors"
  privacy     = "closed"
}

resource "github_team_repository" "admins" {
  for_each = local.active_github_repositories

  team_id    = github_team.admins.id
  repository = github_repository.repositories[each.key].name
  permission = "admin"
}

resource "github_team" "developers" {
  name        = "developers"
  description = "ArgoCD read-only access"
  privacy     = "closed"
}

resource "github_team_membership" "admins_xnoto" {
  team_id  = github_team.admins.id
  username = "xnoto"
  role     = "maintainer"
}
