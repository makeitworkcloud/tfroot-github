# Release Please uses the repository-scoped GITHUB_TOKEN to create its release
# pull request after successful main CI. Keep the default token read-only; the
# release workflow requests only the write scopes it needs at job level.
resource "github_workflow_repository_permissions" "release_automation" {
  repository                       = github_repository.repositories["terraform-libvirt-domain"].name
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}
