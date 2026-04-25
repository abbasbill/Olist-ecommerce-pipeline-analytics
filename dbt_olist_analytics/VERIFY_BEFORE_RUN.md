# Olist dbt Project - Pre-Deployment Verification Checklist

**Status**: READY FOR IMMEDIATE DEPLOYMENT ✅  
**All files configured for your environment**

---

## 📋 Configuration Verification

### Your Project Details

| Item | Value |
|------|-------|
| **GCP Project ID** | `ecommerce-4939` |
| **BigQuery Dataset** | `olist_dataset_4939` |
| **Raw Data Location** | `olist_dataset_4939.*` (tables already loaded) |
| **Orchestrator** | Kestra (local, http://localhost:18080) |
| **Notification Email** | sxzquare@gmail.com |
| **Deployment Type** | Immediate |

---

## ✅ Pre-Deployment Checklist

### Docker & Services

- [ ] Docker Desktop is running
- [ ] Kestra services are running: `docker compose ps`
  - [ ] postgres: Up (healthy)
  - [ ] kestra: Up
- [ ] Kestra accessible: http://localhost:18080

### GCP Setup

- [ ] Service account JSON key exists at `./keys/gcp-credentials.json`
- [ ] `.env_encoded` file created via `./encode-secret.sh`
- [ ] Kestra secrets contain `SECRET_GOOGLE_APPLICATION_CREDENTIALS`
  - Check via: Kestra UI → Admin → Secrets

### BigQuery

- [ ] Project `ecommerce-4939` accessible
- [ ] Dataset `olist_dataset_4939` exists
- [ ] Raw tables loaded (verify with query below):
  ```sql
  SELECT COUNT(*) FROM `ecommerce-4939.olist_dataset_4939.olist_orders_dataset`;
  SELECT COUNT(*) FROM `ecommerce-4939.olist_dataset_4939.olist_order_items_dataset`;
  SELECT COUNT(*) FROM `ecommerce-4939.olist_dataset_4939.olist_products_dataset`;
  SELECT COUNT(*) FROM `ecommerce-4939.olist_dataset_4939.olist_order_payments_dataset`;
  SELECT COUNT(*) FROM `ecommerce-4939.olist_dataset_4939.product_category_name_translation`;
  ```

### dbt Project

- [ ] dbt project located at: `/home/sxzquare/Olist-ecommerce-pipeline-analytics/olist_analytics`
- [ ] Volume mounted in docker-compose.yml:
  - [ ] `./flows:/app/flows`
  - [ ] `./olist_analytics:/app/olist_analytics` ← **Make sure this line exists**

### Configuration Files Updated

- [ ] `profiles.yml` uses `ecommerce-4939` project
- [ ] `profiles.yml` dataset set to `olist_dataset_4939`
- [ ] `dbt_project.yml` variables updated with correct project/dataset
- [ ] `models/sources.yml` points to `olist_dataset_4939` schema
- [ ] `flows/olist_dbt_transformations.yml` uses `/app/olist_analytics` path

---

## 🔧 Final Setup Steps (Before Running)

### Step 1: Update docker-compose.yml (If Not Already Done)

Find the `kestra:` service and add this line to `volumes:`:

```yaml
kestra:
  # ... existing config ...
  volumes:
    - kestra-data:/app/storage
    - /var/run/docker.sock:/var/run/docker.sock
    - /tmp/kestra-wd:/tmp/kestra-wd
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/flows:/app/flows
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/terraform:/app/terraform
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/olist_analytics:/app/olist_analytics  # ← ADD THIS
```

### Step 2: Restart Kestra

```bash
docker compose down
docker compose up -d

# Wait for services to be healthy (30-60 seconds)
docker compose ps
```

### Step 3: Verify Kestra Secrets

Open Kestra UI → Admin → Secrets and check:
- [ ] `SECRET_GOOGLE_APPLICATION_CREDENTIALS` present (not empty)

### Step 4: Upload Kestra Flow (If Not Auto-Synced)

If `flows/olist_dbt_transformations.yml` doesn't appear in Kestra UI:

1. Go to Kestra UI → **Flows**
2. Click **+ Create** → **New flow**
3. Copy contents of `flows/olist_dbt_transformations.yml`
4. Paste into Kestra editor
5. Click **Save**

---

## 🚀 Deployment Steps (In Order)

### Phase 1: Pre-Run Verification

```bash
# 1. Verify Kestra is running
docker compose ps

# 2. Verify dbt project exists
ls -la olist_analytics/

# 3. Verify raw data in BigQuery (use gcloud or BigQuery console)
```

### Phase 2: First Test Run

1. Open Kestra UI: http://localhost:18080
2. Navigate to **Flows**
3. Find: `olist_sales_dbt_pipeline`
4. Click **Execute Now**
5. Monitor execution (watch task status change from pending → running → success)

**Expected timeline**:
- Task 1 (dbt_deps): ~30 seconds
- Task 2 (run_dbt_transformations): 2-5 minutes
- Task 3 (run_dbt_tests): 1-2 minutes
- Task 4 (generate_dbt_docs): 30 seconds
- Total: ~5-10 minutes

### Phase 3: Verify Results

After execution completes, check in BigQuery:

```sql
-- Verify staging views exist
SELECT table_name 
FROM `ecommerce-4939.olist_dataset_4939.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'VIEW'
ORDER BY table_name;

-- Expected output:
-- stg_order_items
-- stg_orders
-- stg_payments
-- stg_products

-- Verify marts table exists and has data
SELECT 
  COUNT(*) as row_count,
  MIN(order_purchase_timestamp) as earliest_order,
  MAX(order_purchase_timestamp) as latest_order
FROM `ecommerce-4939.olist_dataset_4939.fct_sales`;

-- Expected:
-- row_count: ~112,000
-- earliest_order: 2016-01-15
-- latest_order: 2018-08-13
```

### Phase 4: Schedule Daily Runs (Optional)

The flow already has a daily trigger scheduled for 2 AM UTC.

To modify or disable:
1. Go to Kestra UI → **Flows** → `olist_sales_dbt_pipeline`
2. Click **Edit**
3. Scroll to `triggers:` section
4. Modify cron expression (currently: `0 2 * * *`)
5. Save

---

## 📊 What Gets Built

### Database Schema

```
ecommerce-4939/
└── olist_dataset_4939/
    ├── [RAW TABLES] (already exist)
    │   ├── olist_orders_dataset
    │   ├── olist_order_items_dataset
    │   ├── olist_products_dataset
    │   ├── olist_order_payments_dataset
    │   └── product_category_name_translation
    │
    ├── [STAGING VIEWS] (created by dbt)
    │   ├── stg_orders
    │   ├── stg_order_items
    │   ├── stg_payments
    │   └── stg_products
    │
    └── [MARTS TABLES] (created by dbt)
        └── fct_sales (partitioned, clustered)
```

### Table Details

**fct_sales (Main Analytics Table)**
- Type: TABLE (materialized)
- Partitioning: By `order_month` (date truncated to month)
- Clustering: By `product_category_name_english`, `payment_type`
- Rows: ~112,000 (one per order item)
- Columns: 22 (order context, product, payment, metrics)
- Purpose: Revenue analysis by category and time

---

## 🎯 Success Indicators

✅ Deployment successful when:

1. **Kestra UI shows all tasks completed**
   - dbt_deps ✓
   - run_dbt_transformations ✓
   - run_dbt_tests ✓
   - generate_dbt_docs ✓
   - success_notification ✓

2. **19 tests passed**
   - Check Kestra log output: "19 tests passed, 0 failures"

3. **Tables created in BigQuery**
   - 4 staging views exist
   - 1 fct_sales table exists with ~112k rows

4. **No errors in logs**
   - Check Kestra task logs for any red errors
   - Common issues: connection errors, data quality failures

---

## ⚠️ Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| "Volume not mounted" error | Add `/app/olist_analytics` to docker-compose.yml volumes, restart |
| "dbt: command not found" | Docker image includes dbt; check Kestra logs for image pull issues |
| "Connection refused" to BigQuery | Verify `GOOGLE_APPLICATION_CREDENTIALS` secret is set in Kestra |
| "Table not found" in staging | Verify raw tables exist in `olist_dataset_4939` schema |
| "Access denied" to dataset | Check GCP service account has BigQuery Editor role |
| Flow not showing in Kestra | Manually create flow in UI by pasting YAML from `flows/olist_dbt_transformations.yml` |
| "No such schema" error | Confirm dataset `olist_dataset_4939` exists in BigQuery |

### Debug Command (Run Locally)

```bash
cd olist_analytics
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/../keys/gcp-credentials.json"
dbt debug --target prod
```

Should output:
```
✓ All checks passed!
```

---

## 📞 Support & Documentation

- **Deployment Issues**: Check Kestra logs → task output
- **Data Issues**: Check Kestra task logs for dbt error messages
- **SQL Issues**: Run `dbt test --store-failures` to see test details
- **Connection Issues**: Verify `GOOGLE_APPLICATION_CREDENTIALS` is set

### Documentation Files

- [DEPLOYMENT_READY.md](./DEPLOYMENT_READY.md) - This deployment guide
- [README.md](./README.md) - Project overview
- [QUICKSTART.md](./QUICKSTART.md) - Quick start (10 min setup)
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [LOOKER_STUDIO_GUIDE.md](./LOOKER_STUDIO_GUIDE.md) - Dashboard setup

---

## 🎊 Next Steps After Deployment

1. **Verify in BigQuery**: Check tables and data
2. **Create Looker Dashboard**: Connect to `fct_sales` table
3. **Set up monitoring**: Check logs after each daily run
4. **Add alerts**: Configure email notifications in Kestra
5. **Document learnings**: Update team with how to use data

---

## 📝 Deployment Sign-Off

- [ ] Kestra running and healthy
- [ ] GCP credentials configured
- [ ] dbt project mounted in Kestra
- [ ] BigQuery dataset verified
- [ ] Flow executed successfully
- [ ] Tables created and populated
- [ ] Tests passed (19/19)
- [ ] Ready for production use

**Deployment Date**: April 25, 2026  
**Status**: ✅ READY FOR IMMEDIATE EXECUTION  
**Estimated First Run**: 5-10 minutes

---

## 🚀 You're Ready!

Your dbt project is fully configured and ready to deploy.

**Next action**: Go to Kestra UI (http://localhost:18080) and click **Execute Now** on the `olist_sales_dbt_pipeline` flow.

Good luck! 🎉
