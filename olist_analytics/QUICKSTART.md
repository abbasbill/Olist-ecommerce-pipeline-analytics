# Quick Start Guide - Olist dbt Project

Get up and running with the Olist analytics dbt project in 10 minutes.

## 1. Prerequisites

- **Python** >= 3.8
- **Git** (for cloning/versioning)
- **GCP account** with BigQuery access
- **Service Account** with BigQuery Editor role

## 2. Local Setup (for development)

### Clone and Install

```bash
cd olist_analytics
pip install -r requirements.txt
dbt deps
```

### Configure Credentials

```bash
# Copy the profiles template
cp profiles.yml.template profiles.yml

# Edit with your GCP details
nano profiles.yml
```

**What to fill in:**
- `project`: Your GCP project ID
- `keyfile`: Path to GCP service account JSON (e.g., `~/.dbt/gcp-sa-key.json`)

### Test Connection

```bash
dbt debug
```

If successful, you'll see:
```
✓ All checks passed!
```

## 3. Run dbt Models

### Development Run (Test your changes)

```bash
dbt run --target dev
```

This creates views in your `olist_dev` dataset.

### Production Run (Full pipeline)

```bash
dbt run --target prod
```

This creates tables in your `olist_prod` dataset with partitioning/clustering.

### Run Specific Models

```bash
# Just staging models
dbt run --select stg_*

# Just marts
dbt run --select marts

# Specific model
dbt run --select stg_orders
```

## 4. Test Data Quality

```bash
# Run all tests
dbt test

# Test only marts
dbt test --select marts.fct_sales

# See failed tests
dbt test --select marts --fail-fast
```

Expected output:
```
19 tests passed, 0 failures
```

## 5. View Documentation

```bash
dbt docs generate
dbt docs serve
```

Open browser to `http://localhost:8000` to explore:
- Model lineage
- Column descriptions
- Test results
- Raw data definitions

## 6. Common Commands Reference

| Command | Purpose |
|---------|---------|
| `dbt run` | Execute models |
| `dbt test` | Run tests |
| `dbt build` | Run + test (everything) |
| `dbt fresh` | Re-run from scratch |
| `dbt compile` | Check for errors (no execution) |
| `dbt debug` | Test connection |
| `dbt docs generate` | Create documentation |
| `dbt parse` | Validate YAML configs |

## 7. Kestra Integration (Production Orchestration)

### Option A: Run dbt via Kestra (Recommended for Production)

1. Push dbt project to Git:
   ```bash
   git add .
   git commit -m "Add dbt project"
   git push origin main
   ```

2. In Kestra UI:
   - Upload the flow: `flows/olist_dbt_transformations.yml`
   - Set variables: GCP_PROJECT_ID, notification_email
   - Execute: Click **Run**

3. Monitor in Kestra:
   - View logs
   - See execution timeline
   - Get notifications on completion

### Option B: Manual Kestra Task

Create a simple dbt task in your existing Kestra flow:

```yaml
- id: run_dbt
  type: io.kestra.plugin.dbt.cli.DbtCLI
  taskRunner:
    type: io.kestra.plugin.scripts.runner.docker.Docker
  containerImage: ghcr.io/kestra-io/dbt-bigquery:latest
  projectDir: /path/to/olist_analytics
  commands:
    - dbt build --select stg_* marts.fct_sales
```

## 8. Looker Studio Dashboard

After dbt models are created:

1. Open [Looker Studio](https://datastudio.google.com)
2. Connect to BigQuery (`marts.fct_sales`)
3. Create dashboard with:
   - **Tile 1**: Revenue by Product Category (Bar chart)
   - **Tile 2**: Monthly Revenue Trend (Line chart)

See [LOOKER_STUDIO_GUIDE.md](./LOOKER_STUDIO_GUIDE.md) for detailed setup.

## 9. Troubleshooting

### Error: "Could not find profile"

**Solution**: Ensure `profiles.yml` is in project root and `DBT_PROFILES_DIR` is set:
```bash
export DBT_PROFILES_DIR=$PWD
```

### Error: "Access denied to dataset"

**Solution**: Check GCP service account permissions:
```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)"
```

Service account needs: `roles/bigquery.dataEditor`

### Error: "Table not found in dataset"

**Solution**: Verify raw data is loaded to BigQuery:
```sql
SELECT * FROM raw.olist_orders_dataset LIMIT 5;
```

If not found, load Kaggle Olist dataset first.

### Models running but no data

**Solution**: Check filters in `models/marts/fct_sales.sql`:
- Date range: `WHERE order_purchase_timestamp >= TIMESTAMP('2016-01-01')`
- Order status: `WHERE order_status IN ('delivered', 'shipped')`

Adjust if your data falls outside these ranges.

## 10. Next Steps

1. **Verify data**: Run a quick query to check marts table:
   ```sql
   SELECT COUNT(*) as row_count, COUNT(DISTINCT order_id) as order_count
   FROM marts.fct_sales;
   ```

2. **Set up automation**: Schedule dbt runs in Kestra (daily at 2 AM)

3. **Create dashboard**: Build Looker Studio dashboard from `marts.fct_sales`

4. **Monitor quality**: Check test results daily

5. **Iterate**: Add new models as business needs evolve

## File Overview

```
olist_analytics/
├── models/staging/      ← Data cleanup layer
├── models/marts/        ← Analytics-ready tables  
├── tests/               ← Data quality tests
├── macros/              ← Reusable code
├── profiles.yml         ← Connection config (DON'T COMMIT!)
├── dbt_project.yml      ← Project settings
└── README.md            ← Full documentation
```

## Getting Help

- **dbt docs**: https://docs.getdbt.com
- **BigQuery docs**: https://cloud.google.com/bigquery/docs
- **Kestra docs**: https://kestra.io/docs
- **Looker Studio**: https://support.google.com/looker-studio

---

**Ready?** Start with:
```bash
cd olist_analytics
dbt run
dbt test
dbt docs serve
```

Then open http://localhost:8000 🚀
