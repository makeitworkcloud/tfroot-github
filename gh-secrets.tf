locals {
  secret_repo_pairs = flatten([
    for secret_key, secret in local.secrets : [
      for repo in secret.repositories : {
        secret_key = secret_key
        name       = secret.name
        value      = secret.value
        repository = repo
      }
    ]
  ])
}

/*
import {
  for_each = { for pair in local.secret_repo_pairs : "${pair.repository}_${pair.name}" => pair }
  to       = github_actions_secret.secrets["${each.value.repository}_${each.value.name}"]
  id       = "${each.value.repository}/${each.value.name}"
}
*/

resource "github_actions_secret" "secrets" {
  for_each        = { for pair in local.secret_repo_pairs : "${pair.repository}_${pair.name}" => pair }
  repository      = each.value.repository
  secret_name     = each.value.name
  plaintext_value = each.value.value
  depends_on      = [github_repository.repositories]
}