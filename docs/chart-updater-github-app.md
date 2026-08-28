# Chart Updater GitHub App Runbook

This is the canonical operator runbook for the GitHub App used by the chart
updater. Read identifiers, repository names, and secret names from the linked
source configuration instead of copying them into other documentation.

## Purpose and current consumers

The [charts workflow](https://github.com/makeitworkcloud/charts/blob/main/.github/workflows/helm.yml)
publishes an immutable `opencode-server` chart release and uses a short-lived
GitHub App installation token to update the
[GitOps chart reference](https://github.com/makeitworkcloud/kustomize-cluster/blob/main/workloads/apps/opencode-app.yaml).
The workflow opens a pull request; it does not sync Argo CD or deploy the
release.

The current source repository, destination repository, App ID, Actions secret
name, and token repository request are defined in the charts workflow and in
the [`local.secrets` mapping](../main.tf). The Actions secret is materialized by
[`github_actions_secret.secrets`](../gh-secrets.tf).

Chart updater operation does not depend on AWS Secrets Manager. The private key
used by the workflow is stored in this repository's SOPS-backed secret file and
distributed directly to the configured GitHub Actions repository secret. An
old AWS Secrets Manager copy is legacy and unreferenced. It is not part of
normal key rotation or recovery. Deleting that legacy copy requires a separate
approved cleanup after the agreed rollback window.

## Ownership boundaries

| Concern | Owner and source of truth |
| --- | --- |
| GitHub App creation, permissions, keys, and organization installation | Organization owners manage these manually in GitHub. This root does not Terraform-manage the App or its installation. |
| Encrypted private key and Actions secret recipients | This root owns the SOPS-backed value and recipient list in [`main.tf`](../main.tf), using the encryption policy in [`.sops.yaml`](../.sops.yaml). |
| Actions secret distribution | [`gh-secrets.tf`](../gh-secrets.tf) writes the configured repository secret. It cannot create or configure a GitHub App. |
| Chart publication and updater token request | The [charts workflow](https://github.com/makeitworkcloud/charts/blob/main/.github/workflows/helm.yml) owns the App ID reference, requested repositories, requested token permissions, and pull-request automation. |
| Desired deployment state and rollout | `kustomize-cluster` owns the GitOps reference. Follow its [rollout and rollback guide](https://github.com/makeitworkcloud/kustomize-cluster/blob/main/docs/rollout-and-rollback.md). |

## Keep the four scopes distinct

These scopes can overlap, but one never implies another:

| Scope | Where it is configured | What it controls |
| --- | --- | --- |
| Terraform-managed repositories | `local.github_repositories` in [`main.tf`](../main.tf) | Repositories, protections, and other organization configuration managed by this root. It grants no GitHub App access. |
| Repositories receiving the Actions secret | The chart updater entry in `local.secrets` in [`main.tf`](../main.tf) | Source repositories that receive the App private key as an Actions secret. It grants no installation access by itself. |
| App installation repositories | GitHub organization installation settings, with **Only select repositories** | Repositories on which the App installation is authorized. This is manual configuration and is not represented in Terraform state. |
| Workflow-requested token repositories | The `repositories` input in the [charts workflow](https://github.com/makeitworkcloud/charts/blob/main/.github/workflows/helm.yml) | The subset placed on the installation token created for one workflow run. Every requested repository must also be selected in the App installation. |

The source workflow repository needs the Actions secret. It does not need to be
selected in the App installation unless a workflow token also requests access
to that repository. Verify the live installation scope in GitHub rather than
inferring it from this root.

## Initial App creation and installation

App creation and installation are one-time manual organization-owner actions.
Use an approved change record and a secure workstation.

1. Create an organization-owned GitHub App in GitHub's developer settings. Use
   the approved display name and disable webhooks unless a separately approved
   consumer requires them.
2. Set repository permissions to **Contents: Read and write** and **Pull
   requests: Read and write**. Do not grant organization, account, or additional
   repository permissions without a reviewed requirement.
3. Record the resulting App ID in the source workflow's `app-id` input. Treat
   that source reference as canonical; do not duplicate the numeric ID here.
4. Generate a private key. Keep the downloaded key out of the repository,
   terminal output, tickets, chat, and CI logs.
5. Install the App on the organization using **Only select repositories**.
   Select every repository requested by the source workflow and no others. Do
   not select a source repository merely because it receives the Actions
   secret.
6. Put the private key into the existing SOPS-backed field using the key
   replacement procedure below, then distribute it through the reviewed
   Terraform workflow.
7. Remove the downloaded plaintext file from the workstation after the
   encrypted edit is saved and its presence is no longer needed.

## Replace or rotate the SOPS-backed key

For a planned rotation, keep the old GitHub App key active until the new key
has passed smoke verification. GitHub can accept both keys during the overlap.

Before editing, install `sops` and use approved AWS credentials that can use the
KMS recipient configured in [`.sops.yaml`](../.sops.yaml). Do not copy that
recipient into documentation, tickets, or command output.

1. Generate a new private key from the GitHub App settings. Locate the App by
   the `app-id` reference in the source workflow.
2. From a workstation with approved SOPS access, open
   `secrets/secrets.yaml` with `sops secrets/secrets.yaml`.
3. Replace only the existing chart updater field referenced by
   [`main.tf`](../main.tf). Preserve its YAML type and formatting. Save and
   close the SOPS editor without printing, piping, logging, or pasting the
   plaintext key.
4. Confirm the file remains SOPS-encrypted and that the diff contains only the
   expected encrypted field and SOPS metadata changes. Do not attach the diff
   to external systems.
5. Remove the temporary plaintext download. Do not use a command-line argument,
   shell history, Terraform variable, or unencrypted intermediate file to pass
   the key.
6. Open a focused pull request and use the reviewed plan/apply flow below.
7. Verify secret metadata, then complete a real release smoke test before
   deleting the old App key.

## Reviewed plan and apply

Use the repository's [OpenTofu caller](../.github/workflows/opentofu.yml); do not
run an unreviewed local apply.

1. Open a pull request containing only the approved SOPS-backed change and any
   intentional recipient-list change.
2. Require the test and plan checks to pass. Review the plan comment and confirm
   it updates only the expected `github_actions_secret` instances. A key-only
   rotation must not create repositories or claim to modify the GitHub App or
   its installation.
3. Stop if a plan, log, or comment exposes a secret value or unexpected
   sensitive data. Remove the exposure and rotate the affected key before
   continuing.
4. Merge only after review. The push to `main` invokes the environment-gated
   apply path. Confirm the apply job completed successfully before verification.

## Verify secret metadata without retrieving the secret

GitHub Actions secret values cannot be read back. Verify only the metadata:

1. Read the source repository and Actions secret name from
   [`main.tf`](../main.tf).
2. In the source repository, open **Settings > Secrets and variables > Actions**
   and confirm the expected secret exists and its update time follows the
   successful apply.
3. If using the GitHub API, call only the repository Actions secret metadata
   endpoint and select `name`, `created_at`, and `updated_at`. Do not call any
   external secret store or attempt to reconstruct the value.

Example with values taken from source configuration at execution time:

```sh
gh api "repos/<owner>/<source-repository>/actions/secrets/<secret-name>" \
  --jq '{name, created_at, updated_at}'
```

## Smoke verification with a real chart release

Coordinate rotation with the next real `opencode-server` change. Do not reuse
an existing chart version or manufacture a mutable test release; published OCI
chart versions are immutable.

1. Follow the charts repository process to make the real change and increment
   `opencode-server/Chart.yaml` to a new version.
2. Confirm the charts pull request passes repository hygiene, Helm validation,
   rendering, and packaging checks.
3. Merge the chart pull request and confirm the `main` workflow publishes that
   exact version to GHCR.
4. Confirm the scoped GitHub App token step succeeds and the post-publish job
   creates or updates a pull request in the configured destination repository.
5. Verify the generated pull request is authored through the App, changes only
   the intended GitOps chart reference, and pins `targetRevision` to the newly
   published immutable version.
6. Treat the generated pull request as the credential smoke test. Review and
   roll it out separately using the `kustomize-cluster` [rollout and rollback
   guide](https://github.com/makeitworkcloud/kustomize-cluster/blob/main/docs/rollout-and-rollback.md).
   The updater must not sync Argo CD or deploy directly.
7. Delete the old App key only after the new key has passed this smoke test and
   the rollback window is closed.

## Add a new source repository

Adding a source broadens private-key distribution and requires explicit review.

1. If this root should manage the repository itself, add it to
   `local.github_repositories` and add its exact required check-run names to the
   status-check map in [`main.tf`](../main.tf). Do not add it merely to deliver a
   secret if ownership belongs elsewhere.
2. Add the source repository to the chart updater secret's `repositories` list
   in [`main.tf`](../main.tf).
3. Add or update the source workflow to use the canonical Actions secret and
   App ID references. Request explicit `owner`, `repositories`, Contents, and
   Pull requests scopes when creating the installation token.
4. Add only the workflow-requested destination repositories to the manual App
   installation. The new source itself is not automatically an installation
   repository.
5. Complete the reviewed plan/apply, metadata verification, and real-release
   smoke test.

## Add a new destination repository

1. Decide separately whether this root should Terraform-manage the repository.
   If so, update the managed repository and required-check maps in
   [`main.tf`](../main.tf).
2. Add the destination to the App's organization installation using **Only
   select repositories**. This is a manual organization-owner action.
3. Add the destination to the source workflow's `repositories` token request
   and update the workflow logic to make only the approved changes there.
4. Confirm the existing App-level Contents and Pull requests permissions are
   sufficient. Any permission increase requires separate review and manual
   acceptance on the organization installation.
5. If a new source also needs the private key, add it through the source
   procedure. A destination does not need the Actions secret merely because it
   receives commits or pull requests.
6. Validate with a real immutable release and inspect the generated pull
   request before rollout.

## Emergency revocation

If a private key may be exposed, revoke access before restoring automation:

1. Delete the affected private key in the GitHub App settings immediately. If
   the scope of exposure is unclear, suspend or uninstall the organization App
   installation to invalidate installation-token creation broadly.
2. Disable the affected updater workflow if repeated failures or unwanted
   writes are possible. Deleting the repository Actions secret is only a
   temporary containment measure because the next Terraform apply will restore
   the configured secret.
3. Record the revocation time, affected repositories, workflow runs, and any
   App-authored commits or pull requests. Review the organization audit log.
4. Generate a replacement key, update SOPS, and use the reviewed plan/apply
   path. Do not use the legacy AWS Secrets Manager copy as a fallback.
5. Restore the selected-repository installation or workflow only after its
   scope is reviewed, then perform metadata and real-release smoke verification.
6. Revoke any remaining superseded key after recovery is confirmed.

## Audit and rollback

Retain the approved issue or change record, encrypted Git diff, pull-request
reviews, plan/apply checks, GitHub organization audit events, secret metadata
timestamps, release workflow run, and generated GitOps pull request. Never
attach a private key, decrypted SOPS content, Actions secret value, or sensitive
plan output to the audit record.

For a planned rotation, the active old key is the rollback path. If the new key
fails before the old key is revoked, revert the encrypted secret-file change in
a new reviewed pull request and let the environment-gated apply redistribute
the prior value. Restore manual App permissions or selected repositories in
GitHub if those changed. If the old key was already revoked, it cannot be
restored; generate another key and fix forward.

The legacy AWS Secrets Manager copy is unreferenced and outside this rollback
path. Its eventual deletion must be a separate approved cleanup after operators
agree that no rollback window remains.
