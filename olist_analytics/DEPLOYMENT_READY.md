# 🚀 Olist dbt Project - Immediate Deployment Guide

**Status**: Ready for production deployment  
**Timeline**: 5-10 minutes to get running  
**Configuration**: All files pre-configured for your setup

---

## ✅ What's Already Configured

Your dbt project is now pre-configured with:

- ✅ **GCP Project**: `ecommerce-4939` (from variables.tf)
- ✅ **BigQuery Dataset**: `olist_dataset_4939` (raw data already loaded)
- ✅ **Kestra Integration**: All flows point to `/app/olist_analytics`
- ✅ **Credentials**: Configured to use Kestra's `/secrets/gcp-sa.json`
- ✅ **Email Notifications**: Set to sxzquare@gmail.com
- ✅ **Models**: 4 staging + 1 marts table ready to execute

---

## 🔧 Quick Setup (5 Minutes)

### Step 1: Copy dbt Project to Kestra Mounted Volume

Since Kestra mounts `flows/` and `terraform/` directories, you need to also mount the `olist_analytics` directory. Update your `docker-compose.yml` if not already done:

```yaml
kestra:
  # ... existing config ...
  volumes:
    - kestra-data:/app/storage
    - /var/run/docker.sock:/var/run/docker.sock
    - /tmp/kestra-wd:/tmp/kestra-wd
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/flows:/app/flows
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/terraform:/app/terraform
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/olist_analytics:/app/olist_analytics  # ← ADD THIS LINE
```

Then restart Kestra:
```bash
docker compose down
docker compose up -d
```

### Step 2: Verify Kestra GCP Credentials

In Kestra UI:
1. Go to **Admin** → **Secrets**
2. Confirm you see: `SECRET_GOOGLE_APPLICATION_CREDENTIALS`
3. If not present, add it via `.env_encoded` (created by `encode-secret.sh`)

### Step 3: Test dbt Connection Manually (Optional)

```bash
# From your local machine (not in Kestra)
cd olist_analytics
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/keys/gcp-credentials.json"
dbt debug --target prod
```

Expected output:
```
✓ All checks passed!
```

---

## 🎯 Run the dbt Pipeline

### Option A: Run via Kestra UI (Recommended)

1. Open Kestra: http://localhost:18080
2. Go to **Flows** → Find `olist_sales_dbt_pipeline`
3. Click **Execute**
4. Monitor task execution:
   - ✓ dbt_deps (30 sec)
   - ✓ run_dbt_transformations (2-5 min)
   - ✓ run_dbt_tests (1-2 min)
   - ✓ generate_dbt_docs (30 sec)
   - ✓ success_notification (log message)

Expected completion: **5-10 minutes total**

### Option B: Run Manually (For Testing)

```bash
# From inside the container or local machine
cd olist_analytics

# Full build
dbt build --select stg_* marts.fct_sales --target prod

# Run tests
dbt test --select marts.fct_sales --target prod

# Generate docs
dbt docs generate
```

---

## 📊 Verify the Build Succeeded

### In BigQuery Console

Check the tables were created:

```sql
-- Check staging views in olist_dataset_4939
SELECT table_name 
FROM `ecommerce-4939.olist_dataset_4939.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'VIEW'
AND table_name LIKE 'stg_%';

-- Output should show:
-- stg_orders
-- stg_order_items
-- stg_payments
-- stg_products

-- Check marts table
SELECT table_name 
FROM `ecommerce-4939.olist_dataset_4939.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'TABLE'
AND table_name = 'fct_sales';

-- Check data in fct_sales
SELECT COUNT(*) as row_count FROM `ecommerce-4939.olist_dataset_4939.fct_sales`;

-- Should return: ~112k rows (one per order item)
```

### In Kestra UI

1. Go to **Executions** for `olist_sales_dbt_pipeline`
2. Click the latest execution
3. Check each task:
   - ✅ dbt_deps: No errors
   - ✅ run_dbt_transformations: 4 models built successfully
   - ✅ run_dbt_tests: 19 tests passed
   - ✅ success_notification: Logged completion message

---

## 📈 Next Step: Create Looker Studio Dashboard

Once the dbt pipeline runs successfully, you can create the analytics dashboard:

1. **Open Looker Studio**: https://datastudio.google.com
2. **Connect BigQuery**:
   - Create → Report
   - Create new data source → BigQuery
   - Select: `ecommerce-4939` → `olist_dataset_4939` → `fct_sales`
3. **Create Tile 1: Revenue by Category**
   - Chart type: Horizontal Bar
   - Dimension: `product_category_name_english`
   - Metric: `SUM(revenue)`
   - Sort: Descending
4. **Create Tile 2: Monthly Revenue Trend**
   - Chart type: Line Chart
   - Dimension: `order_month`
   - Metric: `SUM(revenue)`
   - Sort: Ascending by date

See [LOOKER_STUDIO_GUIDE.md](../olist_analytics/LOOKER_STUDIO_GUIDE.md) for detailed setup.

---

## 🗓️ Schedule Daily Runs

### Via Kestra UI

1. Go to **Flows** → `olist_sales_dbt_pipeline`
2. Click **Edit** (pencil icon)
3. The flow already has a daily trigger: `0 2 * * *` (2 AM UTC)
4. To modify: Change the cron expression
5. Save

### Manual Trigger (For Testing)

1. Go to **Flows** → `olist_sales_dbt_pipeline`
2. Click **Execute Now**
3. Monitor the run

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Connection failed" in dbt_deps** | Check `GOOGLE_APPLICATION_CREDENTIALS` secret in Kestra |
| **"No such schema: olist_dataset_4939"** | Verify dataset exists in BigQuery (should already be there) |
| **"dbt: command not found"** | Kestra Docker image includes dbt; check container logs |
| **"Table not found" in staging models** | Verify raw tables are in `olist_dataset_4939` schema |
| **Tests failing** | Run `dbt test --store-failures` to see test details |
| **No data in fct_sales** | Check date filters in dbt_project.yml variables (start_date, end_date) |

### Check Kestra Logs

```bash
# View Kestra container logs
docker compose logs -f kestra

# View specific flow execution
# In Kestra UI: Flows → Select flow → Click execution → View Logs tab
```

---

## 📁 Project Files Summary

```
olist_analytics/                    ← Main dbt project
├── dbt_project.yml               ← Pre-configured for ecommerce-4939
├── profiles.yml                  ← Pre-configured for Kestra secrets
├── models/
│   ├── sources.yml               ← Points to olist_dataset_4939
│   ├── staging/                  ← 4 cleaning models
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_payments.sql
│   │   └── stg_products.sql
│   └── marts/
│       └── fct_sales.sql         ← Main analytics table
└── tests/                        ← 19 data quality tests

flows/
└── olist_dbt_transformations.yml  ← Kestra orchestration workflow
```

---

## ✨ What Happens When You Run It

### Execution Flow

```
1. dbt_deps (30 sec)
   ↓ Downloads dbt packages (dbt-utils, audit-helper)
   ↓
2. run_dbt_transformations (2-5 min)
   ↓ Creates 4 staging views in BigQuery
   ↓ Creates 1 marts table (fct_sales) with partitioning/clustering
   ↓
3. run_dbt_tests (1-2 min)
   ↓ Validates: not_null, unique, relationships, accepted_values
   ↓ Checks: revenue >= 0, no future dates
   ↓
4. generate_dbt_docs (30 sec)
   ↓ Creates lineage graph and documentation
   ↓
5. success_notification (instant)
   ↓ Logs completion message
   ↓
✅ COMPLETE! Data ready for Looker Studio
```

### Tables Created in `olist_dataset_4939`

| Table | Type | Purpose | Rows |
|-------|------|---------|------|
| `stg_orders` | View | Clean order data | 99k |
| `stg_order_items` | View | Clean item data | 112k |
| `stg_payments` | View | Aggregated payments | ~45k |
| `stg_products` | View | Products w/ translation | 32k |
| `fct_sales` | Table | Final fact table | 112k |

---

## 🎯 Success Criteria

✅ Pipeline executed successfully when:

1. All 5 tasks complete in Kestra (no red X marks)
2. 19 tests pass (0 failures)
3. `fct_sales` table has ~112k rows
4. No SQL errors in logs
5. Looker Studio can query `fct_sales` table

---

## 🚀 Ready to Deploy

Everything is pre-configured. You're ready to go!

**Quick checklist:**
- [ ] Kestra running (`docker compose ps` shows healthy services)
- [ ] `/app/olist_analytics` mounted in docker-compose.yml
- [ ] GCP credentials in Kestra secrets
- [ ] BigQuery dataset `olist_dataset_4939` exists with raw tables
- [ ] dbt project copied to Kestra flows directory

**Then:**
1. Go to Kestra UI: http://localhost:18080
2. Find flow: `olist_sales_dbt_pipeline`
3. Click **Execute Now**
4. Done! ✅

---

## 📚 Full Documentation

- [README.md](../olist_analytics/README.md) - Project overview
- [QUICKSTART.md](../olist_analytics/QUICKSTART.md) - Quick start guide
- [ARCHITECTURE.md](../olist_analytics/ARCHITECTURE.md) - System architecture
- [LOOKER_STUDIO_GUIDE.md](../olist_analytics/LOOKER_STUDIO_GUIDE.md) - Dashboard setup
- [IMPLEMENTATION_CHECKLIST.md](../olist_analytics/IMPLEMENTATION_CHECKLIST.md) - Complete checklist

---

**Deployment Date**: April 25, 2026  
**Status**: ✅ Ready for production  
**Estimated Runtime**: 5-10 minutes  
**Support Email**: sxzquare@gmail.com
