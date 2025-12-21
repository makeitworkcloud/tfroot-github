resource "github_membership" "admin" {
  username = "xnoto"
  role     = "admin"
}

# Teams for ArgoCD RBAC integration
resource "github_team" "admins" {
  name        = "admins"
  description = "ArgoCD administrators"
  privacy     = "closed"
}

resource "github_team" "developers" {
  name        = "developers"
  description = "ArgoCD read-only access"
  privacy     = "closed"
}

# Team memberships
resource "github_team_membership" "admins_xnoto" {
  team_id  = github_team.admins.id
  username = "xnoto"
  role     = "maintainer"
}
