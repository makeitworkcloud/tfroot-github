terraform {
  # please don't pin terraform versions.
  # stating a required minimum version should be sufficient for most use cases.
  required_version = "> 1.3"

  backend "s3" {}

  # please don't pin provider versions unless there is a known bug being worked around.
  # please add comment-doc when pinning to reference upstream bugs/docs that show the reason for the pin.
  required_providers {
    sops = {
      source = "carlpett/sops"
    }
    github = {
      source = "integrations/github"
    }
  }
}

provider "sops" {}

provider "github" {
  token = data.sops_file.secret_vars.data["github_token"]
  owner = data.sops_file.secret_vars.data["github_owner"]
}

