# GCP Authentication

## Project and state bucket

| Setting | Value |
|---------|-------|
| GCP project | `customer-gtt-halo-20260520` |
| Terraform state bucket | `gs://halo-bucket-20260520` |
| Region | `us-central1` |
| Terraform SA | `terragrunt-sa@customer-gtt-halo-20260520.iam.gserviceaccount.com` |

## How authentication works during `./run`

Terragrunt uses the standard GCP credential chain — it does **not** hardcode a credential
path. In priority order:

1. `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` env var — if set, Terraform impersonates that SA
   using your active `gcloud` session as the source identity.
2. `GOOGLE_APPLICATION_CREDENTIALS` env var — path to a JSON key file (legacy; not used here).
3. Active `gcloud` account — whatever `gcloud config get-value account` returns.

`auth_method: impersonation` in `gcp_seed.yaml` **only controls the seed script**
(`gcp-pkg/_setup/seed`). It does not change how `./run` authenticates. See the comment
in that file for details.

## Day-to-day setup (existing developers)

You need:
1. A `gcloud` session authenticated as a Google account that has been granted
   `serviceAccountTokenCreator` on the Terraform SA (ask the project owner).
2. The `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` env var in your shell:

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=terragrunt-sa@customer-gtt-halo-20260520.iam.gserviceaccount.com
```

Add that to your `~/.bashrc` / `~/.zshrc`. Then authenticate your gcloud session:

```bash
gcloud auth application-default login
```

Verify you can reach the state bucket:

```bash
gsutil ls gs://halo-bucket-20260520/
```

## One-time SA bootstrap (project owner only)

Run once when setting up the project for the first time (or if the SA was deleted).
Requires project owner access to `customer-gtt-halo-20260520`.

```bash
PROJECT=customer-gtt-halo-20260520
SA_NAME=terragrunt-sa
SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"
BUCKET=halo-bucket-20260520

# 1. Create the SA
gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT" \
  --display-name="Terragrunt SA"

# 2. Grant the SA admin on the state bucket (read/write TF state)
gsutil iam ch "serviceAccount:${SA_EMAIL}:roles/storage.objectAdmin" \
  "gs://${BUCKET}"
gsutil iam ch "serviceAccount:${SA_EMAIL}:roles/storage.legacyBucketWriter" \
  "gs://${BUCKET}"

# 3. Grant the SA project-level permissions to manage GCP resources
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"
```

## Managing developers

The `developers[]` list in `gcp_seed_secrets.sops.yaml` is authoritative. Edit the list
and run `--sync-developers` to reconcile GCP IAM: missing developers are granted access,
removed developers have access revoked automatically.

### Add a developer

1. Edit the secrets file:
   ```bash
   sops infra/customer-gtt-pkg/_config/_framework_settings/gcp_seed_secrets.sops.yaml
   ```
   Add under `gcp_seed_secrets.developers`:
   ```yaml
   - name: Jane Smith
     email: jane.smith@example.com
     role: developer
   ```

2. Sync (dry-run first):
   ```bash
   "$_GCP_SEED_MGR" --sync-developers --dry-run
   "$_GCP_SEED_MGR" --sync-developers
   ```

3. Tell the developer to follow the "Day-to-day setup" steps above.

### Remove a developer

1. Delete their entry from `gcp_seed_secrets.developers` in the SOPS file.
2. Run `"$_GCP_SEED_MGR" --sync-developers`.

Their `serviceAccountTokenCreator` binding is revoked automatically.
