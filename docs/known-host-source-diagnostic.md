# Canonical known-host source diagnostic

`tfroot-github` maintains `scripts/check-known-host-source.py` and its sole consumer, the `check-known-host-source` workflow. This is an owner-approved diagnostic for the existing `ssh_known_hosts` distribution path, not a new secret distributor.

The existing `arc-tf` image supplies Python, SOPS and OpenSSH. The helper delegates extraction and matching to SOPS and `ssh-keygen`; no alternate parser, remote key scan, new package, or shared-workflow fork is used. Thin orchestration suppresses their output and removes the temporary file.

## Scope and gates

PR events run synthetic tests only in this new workflow. Source extraction runs only on a manually approved dispatch from `main`, after the tests, using the existing `production` environment and AWS SOPS KMS role. Supply the approved destination as `hero_host`; do not commit it to this repository. No Actions secret is read back, no GitHub secret is written, no host is contacted, and no OpenTofu/state operation runs in this diagnostic.

**The repository's existing OpenTofu workflow is unchanged.** Opening a PR still triggers its usual test/plan. Merging this diagnostic to `main` still triggers the usual main workflow, including its environment-scoped apply job. Review all outstanding infrastructure changes and actual environment protection before merge; installing this diagnostic must not be treated as approval to reapply unrelated infrastructure. A GitHub environment declaration alone does not prove that required-reviewer protection is configured.

After a separately approved merge, use a new manual `check-known-host-source` dispatch from `main`. Do not rerun an old OpenTofu apply as a diagnostic. IAM/KMS access in this new job is not proven until the authorized dispatch succeeds.

## Output contract

The helper extracts the canonical `ssh_known_hosts` field from `secrets/secrets.yaml` inside CI, suppressing SOPS stdout/stderr from logs. A temporary file is held under `$RUNNER_TEMP/known-host-source-check`, directory mode 0700 and file mode 0600. OpenSSH matching output is discarded. Normal success/failure removes the temporary file and directory; an always-run workflow step provides cleanup after interruption. No artifacts or caches contain the extracted material.

Only `source_known_hosts: status=...` is emitted:

- `match-found`: OpenSSH found a matching host entry. This is not proof of key correctness, ordinary ED25519 validity, revocation status, remote identity, or equality with the consumer secret.
- `missing-host-entry`: OpenSSH found no matching destination in the extracted source.
- `source-extraction-failed`: SOPS could not extract the field. No underlying error content is printed.
- `source-unusable`: extraction was empty or exceeded 1 MiB.
- `invalid-input`: empty, dash-prefixed, whitespace/control-bearing target.
- `tool-error`: unavailable tool, timeout, temporary-file error or unexpected failure.

Extraction is bounded to 30 seconds; the match probe to five seconds; the whole step to one minute. The byte limit is checked after capture, not a streaming memory bound. The workflow prints no key material, source contents, fingerprints, hashes, or tool exception details. GitHub may display the non-secret dispatch destination in step environment metadata.

## Interpretation

Compare the source result with `hero-host-config`'s runner-local preflight using the same destination:

1. Source missing: inspect/correct the canonical encrypted field through the trusted owner editing path. Do not rotate the remote key merely because the destination is absent.
2. Source match but consumer missing: investigate the particular Actions-secret resource update and non-sensitive metadata. Neither this check nor a successful apply proves byte-for-byte delivery equality.
3. Both match: keep strict host verification enabled and continue the separately approved Hero check workflow.

There are no changes to `secrets.tf`, `gh-secrets.tf`, encrypted sources, consumer mappings, or the Hero workflow. Rolling back removes the helper/test/workflow/docs through a reviewed PR; no secret or host rollback is needed. CI tests use generated synthetic keys and mocked extraction, never real SOPS/KMS access.
