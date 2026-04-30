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
    "kustomize-cluster",
    "images",
    "shared-workflows",
    "terraform-libvirt-domain",
    "tfroot-aws",
    "tfroot-cloudflare",
    "tfroot-github",
    "tfroot-libvirt",
    "www"
  ])
  archived_github_repositories = toset([
    "ansible-project-libvirt",
    "ansible-site-cluster",
    "ansible-role-crc"
  ])
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
      repositories = ["www"]
    }
    "cloudflare_auth_client_id" = {
      name  = "CLOUDFLARE_AUTH_CLIENT_ID"
      value = data.sops_file.secret_vars.data["cloudflare_auth_client_id"]
      repositories = [
        "images",
        "kustomize-cluster",
        "tfroot-github"
      ]
    }
    "cloudflare_auth_client_secret" = {
      name  = "CLOUDFLARE_AUTH_CLIENT_SECRET"
      value = data.sops_file.secret_vars.data["cloudflare_auth_client_secret"]
      repositories = [
        "images",
        "kustomize-cluster",
        "tfroot-github"
      ]
    }
    "sops_age_key" = {
      name  = "SOPS_AGE_KEY"
      value = data.sops_file.secret_vars.data["sops_age_key"]
      repositories = [
        "tfroot-aws",
        "tfroot-cloudflare",
        "tfroot-github",
        "tfroot-libvirt"
      ]
    }
    "ssh_private_key" = {
      name  = "SSH_PRIVATE_KEY"
      value = data.sops_file.secret_vars.data["ssh_private_key"]
      repositories = [
        "tfroot-libvirt"
      ]
    }
    "ssh_known_hosts" = {
      name  = "SSH_KNOWN_HOSTS"
      value = data.sops_file.secret_vars.data["ssh_known_hosts"]
      repositories = [
        "tfroot-libvirt"
      ]
    }
  }
}
