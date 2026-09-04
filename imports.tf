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
