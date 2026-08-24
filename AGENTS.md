# Agent Instructions

## Repository Purpose

OpenTofu root module for GitHub organization infrastructure.

## Git Workflow

Use a feature branch and open a pull request rather than pushing directly to
`main`. A push to `main` can invoke `apply` after tests pass and configured
environment gates approve it. Do not push any branch unless explicitly
requested.

## Branch Protection

Branch protection on `main` is intentionally relaxed for this solo-maintainer,
personal-dev organization: no required status check contexts and zero required
approving reviews (see the comment in `gh-protections.tf`). PRs are used for CI
validation, plan output, and change history, not as a review gate. Do not
tighten `contexts` or `required_approving_review_count` unless explicitly
requested.

## Pre-commit Configuration

Pre-commit configuration is centralized at
`https://raw.githubusercontent.com/makeitworkcloud/images/main/tfroot-runner/pre-commit-config.yaml`. The root
`.pre-commit-config.yaml` is generated and ignored; do not edit it.

For local development, run:
```bash
make test
```

This refreshes the generated config from the canonical source on every run and
replaces it only when the content changed.

## CI/CD

This repo uses the shared `opentofu.yml` workflow from `shared-workflows`. Jobs
run natively on `arc-tf`; the runner pod already uses the `tfroot-runner` image,
so the workflow does not start a nested container. The shared workflow fetches
the canonical pre-commit config at runtime; this repository does not provide a
tracked copy.

### Failure Modes

**"manifest unknown" error:** The `tfroot-runner:latest` image doesn't exist in GHCR. Check if the `images` repo Build workflow succeeded.

**Pre-commit failures:** If hooks fail unexpectedly, the canonical config may
have changed. Re-run `make test` to refresh it and run the checks.

## Dependency Updates

Dependabot version updates are managed here in `gh-dependabot.tf` via
`github_repository_file` resources, so all active repositories receive their
`.github/dependabot.yml` from one place. To change update policy, edit the
`dependabot_ecosystems` map; do not hand-edit `.github/dependabot.yml` in
downstream repositories. Pre-commit hook revisions are not covered by
Dependabot: they are owned by the canonical config in
`images/tfroot-runner/pre-commit-config.yaml`.

## Related Repositories

- `images` - Contains tfroot-runner image and canonical pre-commit config
- `shared-workflows` - Contains the reusable OpenTofu workflow

## Import ID Formats

Use the provider's resource-specific ID format when adopting existing GitHub
objects:

- repositories: `<repository>`
- `main` branch protections: `<repository>:main`
- Actions secrets: `<repository>/<secret-name>`
- repository files: `<repository>/<file-path>` (append `:<branch>` for non-default branches)
