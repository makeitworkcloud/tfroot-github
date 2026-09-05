# Dependabot version updates are managed centrally here so every active
# repository receives the same `.github/dependabot.yml` policy. Do not add
# hand-maintained dependabot configs to downstream repositories.
#
# OpenTofu roots use the dedicated `opentofu` ecosystem (GA since 2025-12-16),
# not `terraform`. Lock files are not git-tracked in these repos, so only
# version constraints in .tf files are bumped.
#
# Deliberately not covered:
# - pre-commit hook revisions: owned by images/tfroot-runner/pre-commit-config.yaml
# - tool ARG pins in images/*/Containerfile: Dependabot only updates FROM tags
# - Kubernetes image tags in kustomize-cluster: no Dependabot ecosystem exists

locals {
  dependabot_docker_directories = ["gh-cli", "tfroot-runner"]

  dependabot_configs = {
    for name, repository in local.repositories : name => {
      version = 2
      updates = concat(
        [for ecosystem in repository.dependabot_ecosystems : {
          package-ecosystem = ecosystem
          directory         = "/"
          schedule = {
            interval = "daily"
          }
          groups = {
            (ecosystem) = {
              patterns = ["*"]
            }
          }
        } if ecosystem != "docker"],
        [for directory in local.dependabot_docker_directories : {
          package-ecosystem = "docker"
          directory         = "/${directory}"
          schedule = {
            interval = "daily"
          }
          groups = {
            docker = {
              patterns = ["*"]
            }
          }
        } if contains(repository.dependabot_ecosystems, "docker")]
      )
    }
    if length(repository.dependabot_ecosystems) > 0
  }
}

resource "github_repository_file" "dependabot" {
  for_each = local.dependabot_configs

  repository          = github_repository.repositories[each.key].name
  file                = ".github/dependabot.yml"
  content             = "# Managed by tfroot-github (gh-dependabot.tf); local edits are overwritten.\n${yamlencode(each.value)}"
  commit_message      = "chore: sync managed dependabot configuration"
  overwrite_on_create = true

  # These attributes are creation/commit metadata, not the centrally managed
  # file content. Ignoring imported values avoids a protected-branch write when
  # adopting a PR-seeded file; future content changes remain managed.
  lifecycle {
    ignore_changes = [
      commit_message,
      overwrite_on_create,
    ]
  }
}

locals {
  # Caller for the dependabot-notify reusable workflow in shared-workflows.
  # It is named _dependabot-notify.yml there because this root owns the caller
  # path in every repository, including shared-workflows itself.
  dependabot_notify_workflow = templatefile("${path.module}/templates/dependabot-notify.yml.tftpl", {})
}

resource "github_repository_file" "dependabot_notify" {
  for_each = local.dependabot_configs

  repository          = github_repository.repositories[each.key].name
  file                = ".github/workflows/dependabot-notify.yml"
  content             = local.dependabot_notify_workflow
  commit_message      = "chore: sync managed dependabot notification workflow"
  overwrite_on_create = true

  # See github_repository_file.dependabot above. The workflow content remains
  # managed; only imported creation/commit metadata is ignored.
  lifecycle {
    ignore_changes = [
      commit_message,
      overwrite_on_create,
    ]
  }
}
