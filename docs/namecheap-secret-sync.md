# Namecheap API Key Secret Sync

`.github/workflows/namecheap-secret-sync.yml` is a manual recovery/rotation workflow. It is intentionally available only through `workflow_dispatch`, runs on GitHub-hosted `ubuntu-24.04`, and creates a new scoped pull request instead of updating `main`.

## Operator Procedure

1. Confirm that the AWS secret named `xnoto-namecheap-api` has its complete Namecheap API key in `SecretString`; it must not be JSON-wrapped.
2. In this repository, select **Actions**, **namecheap-secret-sync**, and **Run workflow** from `main`.
3. Review the resulting `automation/secret-sync-namecheap-api-<run-id>` pull request. The encrypted file should be the only changed file. Merge it only after normal branch-protection checks pass.
4. If the key is already current, the run exits without creating a branch or pull request.

Do not add inputs to this workflow for secret identifiers or values. The workflow has a fixed allowlist for `xnoto-namecheap-api` and updates only the pre-existing `namecheap_api_key` path in `secrets/secrets.yaml`. It does not print or write decrypted secret material to a file.

## AWS Prerequisites

These resources are intentionally not managed by this OpenTofu root. Before dispatching the workflow, an AWS administrator must configure the following least-privilege prerequisites.

Set these non-secret repository variables:

- `NAMECHEAP_SECRET_SYNC_AWS_ROLE_ARN`: ARN of the dedicated OIDC role.
- `NAMECHEAP_SECRET_SYNC_SECRETS_KMS_KEY_ARN`: CMK ARN that encrypts the `xnoto-namecheap-api` Secrets Manager secret.

The role trust policy must allow only GitHub's OIDC provider, audience `sts.amazonaws.com`, and this repository's `main` ref. For this existing repository, use this subject condition (replace only the account ID in the provider ARN):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::332355796717:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:makeitworkcloud/tfroot-github:ref:refs/heads/main"
      }
    }
  }]
}
```

If this repository has opted into GitHub's immutable OIDC subject claims, use its GitHub-provided immutable `sub` value instead of the legacy value above. Do not broaden the condition to an organization or branch wildcard.

Attach a role policy limited to these resources:

- `secretsmanager:GetSecretValue` for `arn:aws:secretsmanager:us-west-2:332355796717:secret:xnoto-namecheap-api-*`.
- `kms:Decrypt` for `arn:aws:kms:us-west-2:332355796717:key/0a45c0f6-71dc-4d54-ab33-9df4de1a9e91`, which is the SOPS key in `.sops.yaml`.
- `kms:Decrypt` for the CMK in `NAMECHEAP_SECRET_SYNC_SECRETS_KMS_KEY_ARN`.

The workflow applies the same resource limits as an inline session policy, so the role must not rely on broader permissions. The Secrets Manager CMK key policy must also permit this role to decrypt that one secret. No other Secrets Manager secret, KMS key, or AWS action is required.

## Supply Chain

The workflow downloads the `linux.amd64` binary for SOPS `v3.13.3` directly from the official `getsops/sops` GitHub release and verifies SHA-256 `e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b` before execution. GitHub actions are commit-SHA pinned.
