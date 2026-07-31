# Agent Instructions

## Repository Purpose

OpenTofu root module for GitHub organization infrastructure.

## Git Workflow

Use a feature branch and open a pull request rather than pushing directly to
`main`. A push to `main` can invoke `apply` after tests pass and configured
environment gates approve it. Do not push any branch unless explicitly
requested.

## Pre-commit Configuration

Pre-commit configuration is **centralized** in `makeitworkcloud/images/tfroot-runner/pre-commit-config.yaml`. The CI workflow fetches this config at runtime.

**Do not** create or modify `.pre-commit-config.yaml` in this repository.

For local development, run:
```bash
make test
```

This automatically fetches the canonical config if not present.

## CI/CD

This repo uses the shared `opentofu.yml` workflow from `shared-workflows`. Jobs
run natively on `arc-tf`; the runner pod already uses the `tfroot-runner` image,
so the workflow does not start a nested container.

### Failure Modes

**"manifest unknown" error:** The `tfroot-runner:latest` image doesn't exist in GHCR. Check if the `images` repo Build workflow succeeded.

**Pre-commit failures:** If hooks fail unexpectedly, the canonical config may have changed. Delete `.pre-commit-config.yaml` locally and re-run `make test` to fetch the latest.

## Related Repositories

- `images` - Contains tfroot-runner image and canonical pre-commit config
- `shared-workflows` - Contains the reusable OpenTofu workflow and canonical pre-commit config
