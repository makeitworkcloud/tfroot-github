# Agent Instructions

OpenTofu root for Make IT Work Cloud GitHub organization infrastructure.

This root centrally manages organization policy, repository protections, Dependabot callers, and distributed Actions configuration. Before adding a centrally managed path, verify that no target repository owns that same path; preserve the `_dependabot-notify.yml` collision boundary in `shared-workflows`.

`README.md` is generated from `.terraform-docs.yml`; regenerate it instead of editing generated sections by hand. Use `docs/chart-updater-github-app.md` for chart updater GitHub App, installation, and key operations.

Use GitHub MCP and PR CI plans as validation authority. `main` is an environment-gated apply path; use scoped branches and PRs, never direct pushes. Do not run OpenTofu, secret-decryption, curl, import, state, or apply commands from this server. Never expose encrypted secret content, credentials, state, or sensitive plans.
