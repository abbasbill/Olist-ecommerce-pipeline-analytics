## Problem Statement

Background

The Olist Kaggle dataset contains comprehensive transactional records (orders, order_items, payments, products) useful for sales and product analytics. However, the raw CSV files are fragmented, prone to schema drift, and lack an automated, auditable path from raw data to business-ready metrics.

Problem

Analysts and stakeholders cannot reliably answer operational and strategic questions (e.g., revenue trends, category performance, payment behaviour) because data ingestion, transformation, and infrastructure provisioning are manual, brittle, and hard to reproduce.

Project Objective

Implement a reproducible, secure, end-to-end batch pipeline that:
- Ingests Olist CSVs to versioned Google Cloud Storage (GCS)
- Provisions infrastructure (GCS buckets, BigQuery dataset) with Terraform
- Produces tested, documented staging and mart models in BigQuery using dbt
- Orchestrates runs, retries, and notifications using Kestra
- Exposes clean marts for dashboards in Looker Studio

Scope (in-scope)
- Automated Kaggle → GCS ingestion and raw data versioning
- Terraform-managed infra for storage and BigQuery
- dbt `stg_*` and `marts.fct_sales` models with schema + custom tests
- Kestra workflows for ETL + dbt orchestration
- Secret management via encoded environment files or secret stores

Out-of-scope (for now)
- Real-time streaming ingestion
- Advanced access-control automation beyond service-account roles

Success Criteria (measurable)
- Raw data persisted to GCS with versioning on each pipeline run
- Terraform runs produce consistent infra without manual edits
- `dbt build` completes and `dbt test` passes on CI (or local) runs
- Marts refresh within the agreed SLA (e.g., nightly) and surface these KPIs: total revenue, monthly trend, revenue by category

Key Risks & Mitigations
- Credential leakage — never commit keys; prefer Workload Identity and rotate keys
- Schema changes — enforce dbt tests and add CI gate for schema drift
- Cost surprises — partition tables, set lifecycle rules, and monitor spend

Deliverables
- `terraform/` configuration files (`main.tf`, `variables.tf`, `backend.tf`)
- `olist_analytics/` dbt project with models, tests, and docs
- `flows/` Kestra YAML workflows to run ingestion and dbt jobs
- Documentation: `README.md`, `problem_statement.md`, and runbook snippets

Next Steps
1. Finalise `profiles.yml` and secrets locally (do not commit keys).
2. Create the Terraform state bucket and run `terraform init`.
3. Run the Kestra flow to ingest sample data and execute `dbt build`.
