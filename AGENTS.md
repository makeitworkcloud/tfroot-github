# Agent Instructions

## Repository Purpose

OpenTofu root module for GitHub organization infrastructure.

## Git Workflow

Use a feature branch and open a pull request rather than pushing directly to
`main`. A push to `main` can invoke `apply` after tests pass and configured
environment gates approve it. Do not push any branch unless explicitly
requested.

PRs are squash-merged. If a branch contains commits that already landed on
`main` via a squash merge (stacked PRs), a plain rebase or merge replays them
and produces phantom conflicts on the open PR. Rebase with
`git rebase --onto origin/main <last-squashed-commit>` so only the unique
commits replay.

## Branch Protection

Branch protection on `main` is intentionally relaxed for this solo-maintainer,
personal-dev organization: no required status check contexts and zero required
approving reviews (see the comment in `gh-protections.tf`). PRs are used for CI
validation, plan output, and change history, not as a review gate. Do not
tighten `contexts` or `required_approving_review_count` unless explicitly
requested.

GitHub silently drops branch-protection bypass actors that have no repository
access at write time — the apply succeeds but the stored rule omits them, so
config and live state diverge on every plan. The `admins` bypass entries here
are only valid because `gh-iam.tf` grants the team admin access to every
active repository (`github_team_repository.admins`); never remove those
grants while the bypass entries exist, and grant access to any future bypass
team in the same apply.

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

Every `github_repository_file` path is force-written to all repositories in
its `for_each` — including a repository that hand-authors a file at the same
path (observed 2026-08-24: the managed `dependabot-notify.yml` caller
overwrote the reusable workflow in `shared-workflows`, breaking it). Before
adding a managed file, check that no target repository owns that path; when a
repository must own a file itself, place it at a path no managed distribution
covers (see `_dependabot-notify.yml`).

## Dependabot PR Alerting

When Dependabot opens a PR, the managed caller workflow
(`.github/workflows/dependabot-notify.yml`, from `gh-dependabot.tf`) invokes
the `dependabot-notify` reusable workflow in `shared-workflows`
(`.github/workflows/_dependabot-notify.yml` — the underscore path keeps it
clear of this managed file's target, which is written to every repository
including `shared-workflows`), which posts a
synthetic alert to the cluster Alertmanager (`alertmanager.makeitwork.cloud`,
kube-prometheus-stack) behind the Cloudflare Access app managed in
`tfroot-cloudflare/cf-access-alertmanager.tf`. Delivery goes to Discord via
the Alertmanager config Secret in `kustomize-cluster/operators/kube-prometheus-stack`.

The only required secrets are `CLOUDFLARE_AUTH_CLIENT_ID` /
`CLOUDFLARE_AUTH_CLIENT_SECRET` — the "GitHub Actions" Cloudflare Access
service token, distributed here to all active repositories. Alertmanager has
no auth of its own; the Access app is the only gate.

Verify delivery end to end (posts a test message to Discord):

```bash
CF_ID=$(AWS_PROFILE=makeitwork sops decrypt --extract '["cloudflare_auth_client_id"]' secrets/secrets.yaml)
CF_SECRET=$(AWS_PROFILE=makeitwork sops decrypt --extract '["cloudflare_auth_client_secret"]' secrets/secrets.yaml)
curl -fsS -X POST -H "CF-Access-Client-Id: $CF_ID" -H "CF-Access-Client-Secret: $CF_SECRET" \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"DependabotPR","severity":"info"},"annotations":{"summary":"E2E"}}]' \
  https://alertmanager.makeitwork.cloud/api/v2/alerts   # expect HTTP 200
```

A genuinely new Dependabot PR fires `opened` and notifies; `@dependabot
recreate` fires `synchronize`, which the caller's actor filter excludes.

## SOPS Secrets

`secrets/secrets.yaml` is the org secret source (SOPS, AWS KMS; decrypt with
`AWS_PROFILE=makeitwork`). Never print decrypted values: move secrets through
subprocesses (decrypt into a shell variable consumed in the same shell), never
into chat, logs, or tracked plaintext.

To resolve a git conflict on an encrypted file without decrypting, compare the
key sets and per-key ciphertext hashes on both sides. If one side contains
every key the other has, with identical ciphertext except for intended changes,
take that side wholesale.

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
