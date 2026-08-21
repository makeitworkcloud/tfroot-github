# Dependabot version updates are managed centrally here so every active
# repository receives the same `.github/dependabot.yml` policy. Do not add
# hand-maintained dependabot configs to downstream repositories.
#
# Deliberately not covered:
# - pre-commit hook revisions: owned by images/tfroot-runner/pre-commit-config.yaml
# - tool ARG pins in images/*/Containerfile: Dependabot only updates FROM tags
# - Kubernetes image tags in kustomize-cluster: no Dependabot ecosystem exists

locals {
  dependabot_ecosystems = {
    ".github"                  = ["github-actions"]
    "cflan"                    = ["github-actions", "pip"]
    "images"                   = ["github-actions", "docker"]
    "kustomize-cluster"        = ["github-actions"]
    "shared-workflows"         = ["github-actions"]
    "terraform-libvirt-domain" = ["github-actions", "terraform"]
    "tfroot-aws"               = ["github-actions", "terraform"]
    "tfroot-cloudflare"        = ["github-actions", "terraform"]
    "tfroot-github"            = ["github-actions", "terraform"]
    "tfroot-libvirt"           = ["github-actions", "terraform"]
    "www"                      = ["github-actions"]
  }
  dependabot_docker_directories = ["gh-cli", "tfroot-runner"]

  dependabot_configs = {
    for repo, ecosystems in local.dependabot_ecosystems : repo => {
      version = 2
      updates = concat(
        [for ecosystem in ecosystems : {
          package-ecosystem = ecosystem
          directory         = "/"
          schedule = {
            interval = "weekly"
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
            interval = "weekly"
          }
          groups = {
            docker = {
              patterns = ["*"]
            }
          }
        } if contains(ecosystems, "docker")]
      )
    }
  }
}

resource "github_repository_file" "dependabot" {
  for_each = local.dependabot_configs

  repository          = github_repository.repositories[each.key].name
  file                = ".github/dependabot.yml"
  content             = "# Managed by tfroot-github (gh-dependabot.tf); local edits are overwritten.\n${yamlencode(each.value)}"
  commit_message      = "chore: sync managed dependabot configuration"
  overwrite_on_create = true
}
