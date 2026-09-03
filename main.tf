data "sops_file" "secret_vars" {
  source_file = "${path.module}/secrets/secrets.yaml"
}

locals {
  github_repositories = toset([
    ".github",
    "ansible-project-libvirt",
    "ansible-site-cluster",
    "ansible-role-crc",
    "cflan",
    "charts",
    "agent-knowledge",
    "channel-project",
    "kustomize-cluster",
    "images",
    "shared-workflows",
    "terraform-libvirt-domain",
    "tfroot-aws",
    "tfroot-cloudflare",
    "tfroot-gcp",
    "tfroot-github",
    "tfroot-libvirt",
    "tfroot-namecheap",
    "www"
  ])
  archived_github_repositories = toset([
    "ansible-project-libvirt",
    "ansible-site-cluster",
    "ansible-role-crc"
  ])
  private_github_repositories = toset([
    "agent-knowledge",
    "channel-project"
  ])
  topics_by_repository = {
    ".github"                  = ["community-health", "github", "org-profile"]
    "agent-knowledge"          = ["agents", "documentation", "knowledge-base", "opencode"]
    "cflan"                    = ["cloudflare", "dns", "networking", "networkmanager", "python"]
    "channel-project"          = ["cloudflare", "dns", "opentofu", "video-streaming"]
    "charts"                   = ["ghcr", "gitops", "helm", "helm-charts", "oci"]
    "images"                   = ["buildah", "containerfiles", "custom-runners", "github-actions", "opentofu"]
    "kustomize-cluster"        = ["app-of-apps", "argocd", "gitops", "k3s", "ksops", "kustomize", "sops"]
    "shared-workflows"         = ["github-actions", "github-workflows", "opentofu", "reusable-workflows", "shared-workflows"]
    "terraform-libvirt-domain" = ["cloud-init", "libvirt", "libvirt-provider", "terraform-module"]
    "tfroot-aws"               = ["aws-provider", "kms", "opentofu", "s3-backend", "sops", "tfstate"]
    "tfroot-cloudflare"        = ["cloudflare", "cloudflare-access", "cloudflare-tunnel", "opentofu", "s3-backend", "sops", "tfstate"]
    "tfroot-gcp"               = ["gcp", "gcs-backend", "kms", "opentofu", "sops", "tfstate", "workload-identity-federation"]
    "tfroot-github"            = ["github-actions", "opentofu", "s3-backend", "sops", "tfstate", "terraform-provider-github"]
    "tfroot-libvirt"           = ["cloud-init", "k3s", "libvirt", "libvirt-provider", "opentofu", "s3-backend", "sops", "tfstate"]
    "tfroot-namecheap"         = ["cloudflare", "dns", "domains", "namecheap", "opentofu"]
    "www"                      = ["cloudflare", "css", "html", "pwa", "s3", "static-site"]
  }
  relaxed_branch_protection_github_repositories = toset([
    "agent-knowledge"
  ])
  # Repositories where automation-created pull requests merge themselves once
  # required checks pass. GitHub auto-merge is enabled only for these
  # repositories (see gh-repositories.tf). kustomize-cluster receives the
  # charts post-publish opencode-server pin pull request, which merges after
  # its required `test` check passes.
  auto_merge_github_repositories = toset([
    "kustomize-cluster"
  ])
  active_github_repositories = toset([
    for repo in local.github_repositories : repo
    if !contains(local.archived_github_repositories, repo)
  ])
  required_status_checks_by_repository = {
    ".github"                  = ["pre-commit"]
    "cflan"                    = ["lint-and-test (3.10)", "lint-and-test (3.11)", "lint-and-test (3.12)", "lint-and-test (3.13)", "type-check"]
    "charts"                   = ["test"]
    "images"                   = ["checks"]
    "kustomize-cluster"        = ["test"]
    "shared-workflows"         = ["lint"]
    "terraform-libvirt-domain" = ["test"]
    "tfroot-aws"               = ["opentofu / test", "opentofu / plan"]
    "tfroot-cloudflare"        = ["opentofu / test", "opentofu / plan"]
    "tfroot-gcp"               = ["opentofu / test", "opentofu / plan"]
    "tfroot-github"            = ["opentofu / test", "opentofu / plan"]
    "tfroot-libvirt"           = ["opentofu / test", "opentofu / plan"]
    "tfroot-namecheap"         = ["opentofu / test", "opentofu / plan"]
    "www"                      = ["static-checks"]
  }
  secrets = {
    "onion_s3_bucket" = {
      name         = "ONION_AWS_S3_BUCKET"
      value        = data.sops_file.secret_vars.data["onion_s3_bucket"]
      repositories = ["www"]
    }
    "onion_aws_region" = {
      name         = "ONION_AWS_REGION"
      value        = data.sops_file.secret_vars.data["onion_aws_region"]
      repositories = ["www"]
    }
    "onion_access_key_id" = {
      name         = "ONION_AWS_ACCESS_KEY_ID"
      value        = data.sops_file.secret_vars.data["onion_aws_access_key_id"]
      repositories = ["www"]
    }
    "onion_secret_access_key" = {
      name         = "ONION_AWS_SECRET_ACCESS_KEY"
      value        = data.sops_file.secret_vars.data["onion_aws_secret_access_key"]
      repositories = ["www"]
    }
    "www_s3_bucket" = {
      name         = "AWS_S3_BUCKET"
      value        = data.sops_file.secret_vars.data["www_s3_bucket"]
      repositories = ["www"]
    }
    "www_aws_region" = {
      name         = "AWS_REGION"
      value        = data.sops_file.secret_vars.data["www_aws_region"]
      repositories = ["www"]
    }
    "www_access_key_id" = {
      name         = "AWS_ACCESS_KEY_ID"
      value        = data.sops_file.secret_vars.data["www_aws_access_key_id"]
      repositories = ["www"]
    }
    "www_secret_access_key" = {
      name         = "AWS_SECRET_ACCESS_KEY"
      value        = data.sops_file.secret_vars.data["www_aws_secret_access_key"]
      repositories = ["www"]
    }
    "cloudflare_zone_id" = {
      name         = "CLOUDFLARE_ZONE_ID"
      value        = data.sops_file.secret_vars.data["cloudflare_zone_id"]
      repositories = ["www"]
    }
    "cloudflare_api_token" = {
      name         = "CLOUDFLARE_API_TOKEN"
      value        = data.sops_file.secret_vars.data["cloudflare_api_token"]
      repositories = ["www", "tfroot-namecheap", "channel-project"]
    }
    "namecheap_api_key" = {
      name         = "NAMECHEAP_API_KEY"
      value        = data.sops_file.secret_vars.data["namecheap_api_key"]
      repositories = ["tfroot-namecheap", "channel-project"]
    }
    "cloudflare_auth_client_id" = {
      name         = "CLOUDFLARE_AUTH_CLIENT_ID"
      value        = data.sops_file.secret_vars.data["cloudflare_auth_client_id"]
      repositories = setsubtract(local.active_github_repositories, toset(["channel-project"]))
    }
    "cloudflare_auth_client_secret" = {
      name         = "CLOUDFLARE_AUTH_CLIENT_SECRET"
      value        = data.sops_file.secret_vars.data["cloudflare_auth_client_secret"]
      repositories = setsubtract(local.active_github_repositories, toset(["channel-project"]))
    }
    "chart_updater_github_app_private_key" = {
      name  = "CHART_UPDATER_GITHUB_APP_PRIVATE_KEY"
      value = data.sops_file.secret_vars.data["chart_updater_github_app_private_key"]
      repositories = [
        "charts",
        "tfroot-aws",
        "tfroot-cloudflare",
        "tfroot-gcp",
        "tfroot-github",
        "tfroot-libvirt",
        "tfroot-namecheap",
      ]
    }
    "ssh_private_key" = {
      name         = "SSH_PRIVATE_KEY"
      value        = data.sops_file.secret_vars.data["ssh_private_key"]
      repositories = ["tfroot-libvirt"]
    }
    "ssh_known_hosts" = {
      name         = "SSH_KNOWN_HOSTS"
      value        = data.sops_file.secret_vars.data["ssh_known_hosts"]
      repositories = ["tfroot-libvirt"]
    }
  }
}
