import {
  to = github_repository.repositories["tfroot-gcp"]
  id = "tfroot-gcp"
}

import {
  to = github_repository.repositories["channel-project"]
  id = "channel-project"
}

# These files were seeded through tfroot-twilio PR #1 because its temporary
# protection rejects direct file creation. Import them before central management
# so the first reconciled apply does not attempt another protected direct write.
import {
  to = github_repository_file.dependabot["tfroot-twilio"]
  id = "tfroot-twilio:.github/dependabot.yml:"
}

import {
  to = github_repository_file.dependabot_notify["tfroot-twilio"]
  id = "tfroot-twilio:.github/workflows/dependabot-notify.yml:"
}

# The kustomize-cluster dependabot-notify workflow was seeded through the
# pull-request path before this resource instance existed in state; the
# direct write in apply run 189 was rejected by the destination's required
# pull-request protection. The live file content matches the managed
# template exactly, so import it before central management, mirroring the
# tfroot-twilio adoption above.
import {
  to = github_repository_file.dependabot_notify["kustomize-cluster"]
  id = "kustomize-cluster:.github/workflows/dependabot-notify.yml:"
}
