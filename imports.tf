import {
  to = github_repository.repositories["tfroot-gcp"]
  id = "tfroot-gcp"
}

import {
  to = github_repository.repositories["channel-project"]
  id = "channel-project"
}

# These files were seeded through pull requests because protected branches
# reject direct creation. Keep the imports until a reviewed no-op plan confirms
# state ownership and central management of the matching live file.
import {
  to = github_repository_file.dependabot["tfroot-twilio"]
  id = "tfroot-twilio:.github/dependabot.yml:"
}

import {
  to = github_repository_file.dependabot_notify["tfroot-twilio"]
  id = "tfroot-twilio:.github/workflows/dependabot-notify.yml:"
}

import {
  to = github_repository_file.dependabot_notify["kustomize-cluster"]
  id = "kustomize-cluster:.github/workflows/dependabot-notify.yml:"
}
