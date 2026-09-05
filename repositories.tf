locals {
  # This catalog is the single source of truth for centrally managed repository
  # metadata. Resource files derive their collections from it; do not add a
  # repository-specific policy list elsewhere.
  repositories = {
    ".github" = {
      archived                  = false
      private                   = false
      topics                    = ["community-health", "github", "org-profile"]
      protection_profile        = "strict"
      required_status_checks    = ["pre-commit"]
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = false
    }
    "agent-knowledge" = {
      archived                  = false
      private                   = true
      topics                    = ["agents", "documentation", "knowledge-base", "opencode"]
      protection_profile        = "relaxed"
      required_status_checks    = []
      dependabot_ecosystems     = []
      allow_auto_merge          = false
    }
    "ansible-project-libvirt" = {
      archived                  = true
      private                   = false
      topics                    = []
      protection_profile        = "none"
      required_status_checks    = []
      dependabot_ecosystems     = []
      allow_auto_merge          = false
    }
    "ansible-role-crc" = {
      archived                  = true
      private                   = false
      topics                    = []
      protection_profile        = "none"
      required_status_checks    = []
      dependabot_ecosystems     = []
      allow_auto_merge          = false
    }
    "ansible-site-cluster" = {
      archived                  = true
      private                   = false
      topics                    = []
      protection_profile        = "none"
      required_status_checks    = []
      dependabot_ecosystems     = []
      allow_auto_merge          = false
    }
    "cflan" = {
      archived                  = false
      private                   = false
      topics                    = ["cloudflare", "dns", "networking", "networkmanager", "python"]
      protection_profile        = "strict"
      required_status_checks    = ["lint-and-test (3.10)", "lint-and-test (3.11)", "lint-and-test (3.12)", "lint-and-test (3.13)", "type-check"]
      dependabot_ecosystems     = ["github-actions", "pip"]
      allow_auto_merge          = false
    }
    "channel-project" = {
      archived                  = false
      private                   = true
      topics                    = ["cloudflare", "dns", "opentofu", "video-streaming"]
      protection_profile        = "none"
      required_status_checks    = []
      dependabot_ecosystems     = []
      allow_auto_merge          = false
    }
    "charts" = {
      archived                  = false
      private                   = false
      topics                    = ["ghcr", "gitops", "helm", "helm-charts", "oci"]
      protection_profile        = "strict"
      required_status_checks    = ["test"]
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = false
    }
    "hero-host-config" = {
      archived                  = false
      private                   = true
      topics                    = ["ansible", "cloudflare-zero-trust", "configuration-management", "node-exporter", "rhel", "systemd"]
      protection_profile        = "none"
      required_status_checks    = []
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = false
    }
    "images" = {
      archived                  = false
      private                   = false
      topics                    = ["buildah", "containerfiles", "custom-runners", "github-actions", "opentofu"]
      protection_profile        = "strict"
      required_status_checks    = ["checks"]
      dependabot_ecosystems     = ["github-actions", "docker"]
      allow_auto_merge          = false
    }
    "kustomize-cluster" = {
      archived                  = false
      private                   = false
      topics                    = ["app-of-apps", "argocd", "gitops", "k3s", "ksops", "kustomize", "sops"]
      protection_profile        = "strict"
      required_status_checks    = ["test"]
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = true
    }
    "shared-workflows" = {
      archived                  = false
      private                   = false
      topics                    = ["github-actions", "github-workflows", "opentofu", "reusable-workflows", "shared-workflows"]
      protection_profile        = "strict"
      required_status_checks    = ["lint"]
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = false
    }
    "terraform-libvirt-domain" = {
      archived                  = false
      private                   = false
      topics                    = ["cloud-init", "libvirt", "libvirt-provider", "terraform-module"]
      protection_profile        = "strict"
      required_status_checks    = ["test"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-aws" = {
      archived                  = false
      private                   = false
      topics                    = ["aws-provider", "kms", "opentofu", "s3-backend", "sops", "tfstate"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-cloudflare" = {
      archived                  = false
      private                   = false
      topics                    = ["cloudflare", "cloudflare-access", "cloudflare-tunnel", "opentofu", "s3-backend", "sops", "tfstate"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-gcp" = {
      archived                  = false
      private                   = false
      topics                    = ["gcp", "gcs-backend", "kms", "opentofu", "s3-backend", "sops", "tfstate", "workload-identity-federation"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-github" = {
      archived                  = false
      private                   = false
      topics                    = ["github-actions", "opentofu", "s3-backend", "sops", "tfstate", "terraform-provider-github"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-libvirt" = {
      archived                  = false
      private                   = false
      topics                    = ["cloud-init", "k3s", "libvirt", "libvirt-provider", "opentofu", "s3-backend", "sops", "tfstate"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-namecheap" = {
      archived                  = false
      private                   = false
      topics                    = ["cloudflare", "dns", "domains", "namecheap", "opentofu"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "tfroot-twilio" = {
      archived                  = false
      private                   = false
      topics                    = ["opentofu", "s3-backend", "sms", "sops", "twilio"]
      protection_profile        = "strict"
      required_status_checks    = ["opentofu / test", "opentofu / plan"]
      dependabot_ecosystems     = ["github-actions", "opentofu"]
      allow_auto_merge          = false
    }
    "www" = {
      archived                  = false
      private                   = false
      topics                    = ["css", "html", "pwa", "s3", "static-site"]
      protection_profile        = "strict"
      required_status_checks    = ["static-checks"]
      dependabot_ecosystems     = ["github-actions"]
      allow_auto_merge          = false
    }
  }

  active_github_repositories = toset([
    for name, repository in local.repositories : name
    if !repository.archived
  ])
}
