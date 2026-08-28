# Reusable OpenTofu callers and GPLv3 licenses are managed centrally here.
# Do not add hand-maintained copies to the target repositories.
#
# The caller map contains only roots using the shared OpenTofu workflow.
# terraform-libvirt-domain has distinct CI, and tfroot-namecheap has no branch
# yet, so neither can safely receive this caller file.
locals {
  managed_opentofu_workflows = {
    "tfroot-aws" = <<-EOT
      # Managed by tfroot-github (gh-managed-files.tf); local edits are overwritten.
      name: opentofu

      on:
        pull_request:
          branches:
            - main
        push:
          branches:
            - main

      permissions:
        contents: write
        id-token: write
        pull-requests: write

      jobs:
        opentofu:
          # Fork PRs do not run infrastructure-aware OpenTofu jobs.
          if: >-
            github.event_name != 'pull_request' ||
            github.event.pull_request.head.repo.full_name == github.repository
          uses: makeitworkcloud/shared-workflows/.github/workflows/opentofu.yml@main
    EOT
    "tfroot-cloudflare" = <<-EOT
      # Managed by tfroot-github (gh-managed-files.tf); local edits are overwritten.
      name: opentofu

      on:
        pull_request:
          branches:
            - main
        push:
          branches:
            - main

      permissions:
        contents: write
        id-token: write
        pull-requests: write

      jobs:
        opentofu:
          # Fork PRs do not run infrastructure-aware OpenTofu jobs.
          if: >-
            github.event_name != 'pull_request' ||
            github.event.pull_request.head.repo.full_name == github.repository
          uses: makeitworkcloud/shared-workflows/.github/workflows/opentofu.yml@main
    EOT
    "tfroot-gcp" = <<-EOT
      # Managed by tfroot-github (gh-managed-files.tf); local edits are overwritten.
      name: opentofu

      on:
        pull_request:
          branches:
            - main
        push:
          branches:
            - main

      permissions:
        contents: write
        id-token: write
        pull-requests: write

      jobs:
        opentofu:
          # Fork PRs do not run infrastructure-aware OpenTofu jobs.
          if: >-
            github.event_name != 'pull_request' ||
            github.event.pull_request.head.repo.full_name == github.repository
          uses: makeitworkcloud/shared-workflows/.github/workflows/opentofu.yml@main
          with:
            gcp-workload-identity-provider: projects/920734942788/locations/global/workloadIdentityPools/github/providers/github
            gcp-service-account: terraformer@makeitworkcloud.iam.gserviceaccount.com
    EOT
    "tfroot-github" = <<-EOT
      # Managed by tfroot-github (gh-managed-files.tf); local edits are overwritten.
      name: opentofu

      on:
        pull_request:
          branches:
            - main
        push:
          branches:
            - main

      permissions:
        contents: write
        id-token: write
        pull-requests: write

      jobs:
        opentofu:
          # Fork PRs do not run infrastructure-aware OpenTofu jobs.
          if: >-
            github.event_name != 'pull_request' ||
            github.event.pull_request.head.repo.full_name == github.repository
          uses: makeitworkcloud/shared-workflows/.github/workflows/opentofu.yml@main
    EOT
    "tfroot-libvirt" = <<-EOT
      # Managed by tfroot-github (gh-managed-files.tf); local edits are overwritten.
      name: opentofu

      on:
        pull_request:
          branches:
            - main
        push:
          branches:
            - main

      permissions:
        contents: write
        id-token: write
        pull-requests: write

      jobs:
        opentofu:
          # Fork PRs do not run infrastructure-aware OpenTofu jobs.
          if: >-
            github.event_name != 'pull_request' ||
            github.event.pull_request.head.repo.full_name == github.repository
          uses: makeitworkcloud/shared-workflows/.github/workflows/opentofu.yml@main
          with:
            # Native tfroot-runner scale set in kustomize-cluster/workloads/arc.
            # The runner pod IS the tfroot-runner image — no nested container.
            runs-on: arc-tf
            setup-ssh: true
          secrets:
            SSH_PRIVATE_KEY: $${{ secrets.SSH_PRIVATE_KEY }}
            SSH_KNOWN_HOSTS: $${{ secrets.SSH_KNOWN_HOSTS }}
    EOT
  }

  # tfroot-namecheap is intentionally excluded until it has a default branch;
  # github_repository_file cannot create a file on an absent branch.
  managed_license_repositories = setsubtract(
    local.active_github_repositories,
    toset(["tfroot-namecheap"])
  )
}

resource "github_repository_file" "opentofu_workflow" {
  for_each = local.managed_opentofu_workflows

  repository          = github_repository.repositories[each.key].name
  file                = ".github/workflows/opentofu.yml"
  content             = each.value
  commit_message      = "chore: sync managed OpenTofu workflow"
  overwrite_on_create = true
}

resource "github_repository_file" "license" {
  for_each = local.managed_license_repositories

  repository          = github_repository.repositories[each.key].name
  file                = "LICENSE"
  content             = file("${path.module}/LICENSE")
  commit_message      = "chore: sync GPLv3 license"
  overwrite_on_create = true
}
