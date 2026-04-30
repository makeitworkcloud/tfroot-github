terraform {
  # please don't pin terraform versions.
  # stating a required minimum version should be sufficient for most use cases.
  required_version = "> 1.3"

  # Dummy values are present only so `terraform validate` can validate the
  # backend schema. These values are overridden by the Makefile during init.
  backend "s3" {
    bucket = "validation-only"
    key    = "validation-only.tfstate"
    region = "us-east-1"
  }

  # please don't pin provider versions unless there is a known bug being worked around.
  # please add comment-doc when pinning to reference upstream bugs/docs that show the reason for the pin.
  required_providers {
    sops = {
      source = "carlpett/sops"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "sops" {}

provider "github" {
  token = data.sops_file.secret_vars.data["github_token"]
  owner = data.sops_file.secret_vars.data["github_owner"]
}
