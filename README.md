# ecommerce-olist-analytics-pipeline
End-to-End Batch Data Engineering Pipeline on GCP – Overview, Architecture Plan &amp; Data Flow

## Prerequisites

1. GCP Service Account
# GCP Service Account Setup Guide

A step-by-step walkthrough to create a GCP service account with BigQuery Admin, Storage Admin, and Storage Object Admin roles, and generate a private key for authentication.

---

## Step 1 — Open GCP Console & select project

**Start at:** `console.cloud.google.com`

1. Go to [console.cloud.google.com](https://console.cloud.google.com) in your browser and sign in with your Google account.
2. In the top navigation bar, click the **project dropdown** (next to the Google Cloud logo).
3. Select an existing project, or click **New Project** to create one. Note your Project ID — you'll need it later.
4. Once selected, confirm the correct project name appears in the top bar before continuing.

> **Tip:** Your Project ID is different from the Project Name. The ID is permanent and used in API calls. Find it in the dropdown or on the project dashboard.

---

## Step 2 — Navigate to IAM & Admin → Service Accounts

1. Click the **hamburger menu** (three lines) in the top left to open the navigation panel.
2. Scroll down to **IAM & Admin** and expand it, then click **Service Accounts**.
3. Alternatively, use the search bar at the top, type *Service Accounts*, and select it from the results.
4. You will now see a list of existing service accounts for the project (or an empty list if none exist).

> **Tip:** You can also navigate directly: `console.cloud.google.com/iam-admin/serviceaccounts`

---

## Step 3 — Create a new service account

1. Click the **+ Create Service Account** button at the top of the page.
2. In the **Service account name** field, enter a descriptive name (e.g. `Olist-data-pipeline-sa`). The ID will auto-fill.
3. Optionally add a **Description** to explain what this account is used for.
4. Click **Create and continue** to proceed to the permissions step.

> **Tip:** Service account IDs must be 6–30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens.

---

## Step 4 — Assign the three required roles

1. In the **Grant this service account access to project** section, click **+ Add Another Role** for each role below.
2. Search for and select **BigQuery Admin** — this grants full control over BigQuery datasets and jobs.
3. Click **+ Add Another Role** again. Search for and select **Storage Admin** — grants full control of GCS buckets.
4. Click **+ Add Another Role** once more. Search for and select **Storage Object Admin** — grants read/write access to objects inside buckets.
5. After adding all three, click **Continue**, then **Done** to finish creating the account.

**Roles to assign:**
- `BigQuery Admin`
- `Storage Admin`
- `Storage Object Admin`

> ⚠️ **Warning:** These are powerful roles. In production, follow the principle of least privilege and restrict access to specific datasets/buckets rather than granting project-wide admin roles.

---

## Step 5 — Open the service account & go to Keys

1. After creation, you'll be back on the Service Accounts list. Click on the **email address** of your newly created service account.
2. This opens the service account's detail page. Click the **Keys** tab at the top.
3. You will see an empty key list with an **Add Key** button.

> **Tip:** If you're not redirected automatically, go back to IAM & Admin → Service Accounts and click the account name.

---

## Step 6 — Generate and download the private key

1. Click **Add Key** → **Create new key**.
2. In the dialog, ensure **JSON** is selected as the key type (recommended over P12).
3. Click **Create**. The key file will **automatically download** to your machine.
4. Rename the file to something descriptive (e.g. `my-project-sa-key.json`) and move it to a secure location.
5. The file contains your private key. **Do not commit it to version control.**

> ⚠️ **Warning:** This is the only time you can download this key. If lost, you must delete it and generate a new one. Store it securely — treat it like a password.

---

## Step 7 — Use the key for authentication

1. Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to your downloaded JSON key file.
2. GCP client libraries (Python, Node.js, Go, Java, etc.) automatically detect this variable.
3. Alternatively, pass the key file path directly in your application code using the SDK.

**Bash / terminal:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/key.json"
```

**Python (explicit):**
```python
from google.oauth2 import service_account
creds = service_account.Credentials.from_service_account_file("key.json")
```

---

## Summary

| Step | Action |
|------|--------|
| 1 | Open GCP Console and select your project |
| 2 | Navigate to IAM & Admin → Service Accounts |
| 3 | Create a new service account |
| 4 | Assign BigQuery Admin, Storage Admin, Storage Object Admin roles |
| 5 | Open the Keys tab on the service account |
| 6 | Generate and download a JSON private key |
| 7 | Set `GOOGLE_APPLICATION_CREDENTIALS` to authenticate |

**Security reminders:**
- Never commit your JSON key file to Git or any public repository.
- Rotate keys regularly and delete unused ones.
- For GCP-hosted workloads, prefer Workload Identity over key files.


2. BigQuery credentials
    - Project ID
    - Private key
    - Client email
    
    >Learn more about obtaining BigQuery credentials in `dlt`'s [documentation](https://dlthub.com/docs/dlt-ecosystem/destinations/bigquery).

## TERRAFORM Setup Guide
# GCP Infrastructure Provisioning with Terraform & Service Account

> **GCS Raw Data Bucket | Terraform State Bucket | BigQuery Dataset**

---

## Overview

This guide walks you through using the GCP service account you created to provision the following infrastructure using Terraform:

- A GCS bucket for raw CSV data ingestion (`olist-bucket-484923`)
- A GCS bucket dedicated to storing Terraform remote state (`terraform-state-484923`)
- A BigQuery dataset for creating tables from GCS data (`olist_dataset_484923`)

> **Tip:** Make sure you have completed the service account setup and downloaded your JSON key file before proceeding.

---

## Prerequisites

Ensure the following tools and files are ready before starting:

- **Terraform** installed (v1.0+) — https://developer.hashicorp.com/terraform/install
- **Google Cloud SDK** (`gcloud`) installed and authenticated
- Your **service account JSON key file** downloaded (e.g. `my-project-sa-key.json`)
- The three `.tf` files from your project: `main.tf`, `variables.tf`, `backend.tf`

> **Tip:** Your service account must have BigQuery Admin, Storage Admin, and Storage Object Admin roles assigned.

---

## Step 1 — Create the Terraform State Bucket manually

> *This bucket must exist before running `terraform init`*

The Terraform state bucket (`terraform-state-484923`) must be created **before** running any Terraform commands, because it is referenced in the backend configuration that Terraform needs during initialisation.

### Option A — Using the GCP Console

1. Go to `console.cloud.google.com` and navigate to **Cloud Storage > Buckets**.
2. Click **Create Bucket**.
3. Set the name to exactly: `terraform-state-484923` (must match `backend.tf`).
4. Choose a region (e.g. `US` or `us-central1` to match your `variables.tf`).
5. Leave other settings as default and click **Create**.

### Option B — Using gcloud CLI

```bash
# Authenticate using your service account key
gcloud auth activate-service-account \
  --key-file=/path/to/my-project-sa-key.json

# Create the Terraform state bucket
gcloud storage buckets create gs://terraform-state-484923 \
  --project=de-project-484923 \
  --location=US
```

> **Note:** The bucket name `terraform-state-484923` must match exactly what is in your `backend.tf` file. Do not change it unless you update both places.

---

## Step 2 — Set up your project file structure

> *Organise the three Terraform configuration files*

Create a project directory and place all three Terraform files inside it:

```
my-terraform-project/
  ├── main.tf          # GCS raw bucket + BigQuery dataset resources
  ├── variables.tf    # All configurable variables
  └── backend.tf      # Remote state configuration
```

Your three files should contain exactly the following:

### main.tf

```terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "raw" {
  name     = var.gcs_bucket_name
  location = var.location

  storage_class               = var.gcs_storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }

  force_destroy = true
}

resource "google_bigquery_dataset" "staging" {
  dataset_id = var.bq_dataset_name
}
```

### variables.tf

```terraform
variable "project" {
  description = "Project"
  default     = "de-project-484923"
}

variable "region" {
  description = "Region"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "olist-bucket-484923"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "olist_dataset_484923"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
```

### backend.tf

```terraform
terraform {
  backend "gcs" {
    bucket = "terraform-state-484923"
    prefix = "terraform/state"
  }
}
```

---

## Step 3 — Set the GOOGLE_APPLICATION_CREDENTIALS environment variable

> *Point Terraform to your service account key*

Terraform uses the Google provider which automatically detects the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to authenticate API calls using your service account.

### Linux / macOS

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/my-project-sa-key.json"

# Verify it is set
echo $GOOGLE_APPLICATION_CREDENTIALS
```

### Windows (PowerShell)

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\my-project-sa-key.json"

# Verify it is set
echo $env:GOOGLE_APPLICATION_CREDENTIALS
```

> **Tip:** Set this variable in every terminal session before running Terraform. For permanent setup, add it to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.).

> **Warning:** Never hardcode the key file path inside your `.tf` files or commit the JSON key to version control.

---

## Step 4 — Review and customise variables

> *Update defaults to match your project*

The variables below are preconfigured in `variables.tf`. Review each one and update the defaults if your project uses different values:

| Variable | Default Value | What to change |
|---|---|---|
| `project` | `de-project-484923` | Your GCP Project ID |
| `region` | `us-central1` | Your preferred GCP region |
| `location` | `US` | Multi-region or single region |
| `gcs_bucket_name` | `olist-bucket-484923` | Must be globally unique |
| `bq_dataset_name` | `olist_dataset_484923` | Your BigQuery dataset name |
| `gcs_storage_class` | `STANDARD` | `STANDARD`, `NEARLINE`, or `COLDLINE` |

> **Note:** GCS bucket names are globally unique across all GCP projects. If the default name is already taken, change it to something unique.

---

## Step 5 — Initialise Terraform

> *Run `terraform init` to set up the backend and download providers*

Navigate into your project directory and run `terraform init`. This will:

- Download the `hashicorp/google` provider plugin (`~7.24.0`)
- Connect to the GCS backend bucket (`terraform-state-484923`) to store state
- Verify authentication using your service account credentials

```bash
cd my-terraform-project

terraform init
```

Expected output on success:

```
Initializing the backend...
Successfully configured the backend "gcs"!

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 7.24.0"...
- Installing hashicorp/google v7.24.x...

Terraform has been successfully initialized!
```

> **Warning:** If you see an error about the state bucket not existing, go back to Step 1 and create it first.

---

## Step 6 — Plan the infrastructure

> *Preview what Terraform will create*

Run `terraform plan` to preview all resources that will be provisioned. No changes are made at this stage.

```bash
terraform plan
```

Terraform will show a plan with 2 resources to be created:

- `google_storage_bucket.raw` — the `olist-bucket-484923` GCS bucket
- `google_bigquery_dataset.staging` — the `olist_dataset_484923` BigQuery dataset

```
Plan: 2 to add, 0 to change, 0 to destroy.
```

> **Tip:** Review the plan carefully before applying. Check that bucket names, regions, and dataset IDs match your expectations.

---

## Step 7 — Apply the configuration

> *Provision all infrastructure resources*

Run `terraform apply` to create the resources in GCP. Terraform will display the plan again and ask for confirmation.

```bash
terraform apply
```

When prompted, type `yes` and press Enter to confirm:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Expected output on success:

```
google_storage_bucket.raw: Creating...
google_bigquery_dataset.staging: Creating...
google_storage_bucket.raw: Creation complete after 2s
google_bigquery_dataset.staging: Creation complete after 3s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

> **Tip:** The Terraform state file is automatically saved to `gs://terraform-state-484923/terraform/state` after a successful apply.

---

## Step 8 — Verify resources in GCP Console

> *Confirm all three resources were created*

After a successful apply, verify each resource in the GCP Console:

### GCS Raw Data Bucket

1. Go to **Cloud Storage > Buckets**.
2. Confirm `olist-bucket-484923` appears in the list.
3. Click into it and verify versioning is enabled under the **Configuration** tab.

### GCS Terraform State Bucket

1. In **Cloud Storage > Buckets**, confirm `terraform-state-484923` exists.
2. Click into it and navigate to `terraform/state/` — you should see the state file.

### BigQuery Dataset

1. Go to **BigQuery** in the GCP Console.
2. In the left panel, expand your project (`de-project-484923`).
3. Confirm `olist_dataset_484923` appears as a dataset.

> **Tip:** All three resources should now be visible in the GCP Console. The dataset will be empty until you create tables inside it.

---

## Step 9 — Load CSV data into GCS and create a BigQuery table

> *Ingest raw data from GCS into BigQuery*

With the infrastructure in place, you can now upload raw CSV files to GCS and create external or native BigQuery tables from them.


## Teardown (Optional)

To destroy all Terraform-managed resources (GCS raw bucket + BigQuery dataset) when no longer needed:

```bash
terraform destroy
```

> **Warning:** This will permanently delete the GCS raw bucket and BigQuery dataset including all data. The Terraform state bucket (`terraform-state-484923`) is not managed by Terraform and must be deleted manually if needed.

---

## Summary

| Step | Action | Key detail |
|---|---|---|
| 1 | Create state bucket manually | `terraform-state-484923` must exist before `terraform init` |
| 2 | Set up `.tf` file structure | `main.tf`, `variables.tf`, `backend.tf` in one directory |
| 3 | Set `GOOGLE_APPLICATION_CREDENTIALS` | Points Terraform to your service account JSON key |
| 4 | Review `variables.tf` | Update project ID, bucket name, region as needed |
| 5 | Run `terraform init` | Downloads provider, connects to GCS backend |
| 6 | Run `terraform plan` | Previews 2 resources: GCS bucket + BQ dataset |
| 7 | Run `terraform apply` | Creates `olist-bucket-484923` and `olist_dataset_484923` |
| 8 | Verify in GCP Console | Check Cloud Storage and BigQuery in the Console |

**Security reminders:**
- Never commit your JSON key file to Git or any public repository.
- Set `GOOGLE_APPLICATION_CREDENTIALS` per session or in your shell profile — never hardcode it in `.tf` files.



2. **Create an .env File**: Within your repository, create an ``.env`` file, copy and paste your secret keys
 To securely store credentials in base64 format. Prefix each secret with 'SECRET_' by executing the `encode-secret.sh bash script` in order for Kestra's [`secret()`](https://kestra.io/docs/developer-guide/variables/function/secret) function to work. The file should look like this: 

    ```env
    SECRET_BIGQUERY_PROJECT_ID=someSecretValueInBase64
    SECRET_BIGQUERY_PRIVATE_KEY=someSecretValueInBase64
    SECRET_BIGQUERY_CLIENT_EMAIL=someSecretValueInBase64

    ```

   >The base64 format is required because Kestra mandates it.
  
    Find out more about managing secrets in Kestra [here](https://kestra.io/docs/developer-guide/secrets).

3. **Download Docker Desktop**: As recommended by Kestra, download and install Docker Desktop.

4. **Download Docker Compose File**: Verify that Docker is active and download the Docker Compose file using the following command:
   ```bash
    curl -o docker-compose.yml \
    https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
    ```
    *
5. **Configure Docker Compose File**: Modify your Docker Compose file to include the ``.env`` file:

    ```yaml
    kestra:
        image: kestra/kestra:develop-full
        env_file:
            - .env
    ``` 

6. **Enable Auto-Restart in Docker Compose**: Add ``restart: always`` to the `postgres` and `kestra` services in your `docker-compose.yml`. This ensures they automatically restart after a system reboot:

    ```yaml
    postgres:
        image: postgres
        restart: always
    ```

    ```yaml
    kestra:
        image: kestra/kestra:latest-full
        restart: always
    ```
7. **Start Kestra Server**: Run the following command:
   ```bash
    docker compose up -d
    ```
8. **Access Kestra UI**: Launch http://localhost:8080/ to open the Kestra UI.


## REFERENCES
- [Configure Secrets in Kestra](https://kestra.io/docs/how-to-guides/secrets)
- [Secrets in Kestra – Store Sensitive Values Securely](https://kestra.io/docs/concepts/secret)