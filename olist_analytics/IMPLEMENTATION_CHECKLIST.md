# Implementation Checklist - Olist Analytics Pipeline

Complete step-by-step checklist to deploy the Olist analytics pipeline.

## Phase 1: Prerequisites & Setup ✓

- [ ] **GCP Project Setup**
  - [ ] Create/select GCP project
  - [ ] Enable BigQuery API
  - [ ] Enable Cloud IAM API
  - [ ] Record project ID: `_________________`

- [ ] **Create Service Account**
  - [ ] Go to GCP Console → IAM → Service Accounts
  - [ ] Click "Create Service Account"
  - [ ] Name: `olist-dbt-service-account`
  - [ ] Grant role: `BigQuery Data Editor`
  - [ ] Create JSON key: Download and save securely
  - [ ] Save key location: `_________________`

- [ ] **Python Environment**
  - [ ] Python 3.8+ installed
  - [ ] Virtual environment created: `python -m venv venv`
  - [ ] Activated: `source venv/bin/activate`

- [ ] **Kestra Setup** (if using for orchestration)
  - [ ] Kestra installed locally or cloud instance running
  - [ ] Access Kestra UI: `http://localhost:8080`
  - [ ] Create namespace: `olist`
  - [ ] Record Kestra API URL: `_________________`

## Phase 2: dbt Project Configuration ✓

- [ ] **Install Dependencies**
  - [ ] Run: `cd olist_analytics && pip install -r requirements.txt`
  - [ ] Verify: `dbt --version` (should show 1.5.x)

- [ ] **Configure Profiles**
  - [ ] Edit: `olist_analytics/profiles.yml`
  - [ ] Fill in:
    - [ ] `project`: YOUR_GCP_PROJECT_ID
    - [ ] `keyfile`: Path to service account JSON
    - [ ] `dataset`: olist_dev (dev target), olist_prod (prod target)
  - [ ] Test: `dbt debug`
  - [ ] Result should show: ✓ All checks passed!

- [ ] **Update dbt_project.yml** (if customizing)
  - [ ] Review variables section
  - [ ] Update `start_date` and `end_date` if different date range needed
  - [ ] Verify model paths and test paths

## Phase 3: Data Preparation ✓

- [ ] **Verify Raw Data in BigQuery**
  - [ ] Schema: `raw`
  - [ ] Tables exist:
    - [ ] olist_orders_dataset (99k rows)
    - [ ] olist_order_items_dataset (112k rows)
    - [ ] olist_products_dataset (32k rows)
    - [ ] olist_order_payments_dataset (103k rows)
    - [ ] product_category_name_translation (71 rows)
  - [ ] Quick check:
    ```sql
    SELECT COUNT(*) FROM raw.olist_orders_dataset;
    ```

- [ ] **Create BigQuery Datasets** (if they don't exist)
  ```sql
  CREATE SCHEMA IF NOT EXISTS olist_dev;
  CREATE SCHEMA IF NOT EXISTS olist_prod;
  CREATE SCHEMA IF NOT EXISTS stg;
  CREATE SCHEMA IF NOT EXISTS marts;
  ```

## Phase 4: Local Testing ✓

- [ ] **Parse Models** (syntax check)
  - [ ] Run: `dbt parse`
  - [ ] Result: No errors

- [ ] **Compile Models** (prepare for execution)
  - [ ] Run: `dbt compile --select stg_*`
  - [ ] Check: `target/compiled/` directory created

- [ ] **Run Staging Models** (dev environment)
  - [ ] Run: `dbt run --select stg_* --target dev`
  - [ ] Expected: 4 views created in `olist_dev.stg` schema
  - [ ] Verify in BigQuery:
    ```sql
    SELECT * FROM olist_dev.stg_orders LIMIT 5;
    ```

- [ ] **Run Marts Models** (dev environment)
  - [ ] Run: `dbt run --select marts.fct_sales --target dev`
  - [ ] Expected: 1 table created in `olist_dev.marts` schema
  - [ ] Check row count:
    ```sql
    SELECT COUNT(*) as row_count FROM olist_dev.marts.fct_sales;
    ```

- [ ] **Run Tests** (data quality)
  - [ ] Run: `dbt test`
  - [ ] Expected: 19 tests passed, 0 failures
  - [ ] If failures: Review dbt logs for issues

- [ ] **Generate Documentation**
  - [ ] Run: `dbt docs generate`
  - [ ] View: `dbt docs serve`
  - [ ] Confirm: Model lineage visible at http://localhost:8000

## Phase 5: Production Build ✓

- [ ] **Run Production Build** (prod environment)
  - [ ] Run: `dbt run --target prod`
  - [ ] Expected: Staging views + marts table in `olist_prod` schema
  - [ ] Verify partitioning applied:
    ```sql
    SELECT partition_field FROM `PROJECT.olist_prod.INFORMATION_SCHEMA.PARTITIONS`
    WHERE table_name = 'fct_sales';
    ```

- [ ] **Run Full Build** (run + test)
  - [ ] Run: `dbt build --target prod`
  - [ ] Expected: All models created + tests pass

- [ ] **Verify Marts Table Quality**
  - [ ] Row count: Should match order items count (~112k)
  - [ ] No nulls in critical columns:
    ```sql
    SELECT COUNT(*) 
    FROM olist_prod.marts.fct_sales
    WHERE revenue IS NULL;  -- Should be 0
    ```

## Phase 6: Looker Studio Dashboard ✓

- [ ] **Connect BigQuery to Looker Studio**
  - [ ] Go to https://datastudio.google.com
  - [ ] Create → Report
  - [ ] Create new data source → BigQuery
  - [ ] Authorize
  - [ ] Select project → dataset: `marts` → table: `fct_sales`

- [ ] **Create Tile 1: Revenue by Category**
  - [ ] Add chart → Horizontal Bar Chart
  - [ ] Dimension: `product_category_name_english`
  - [ ] Metric: `SUM(revenue)`
  - [ ] Sort: Descending, Top 15
  - [ ] Format: BRL currency
  - [ ] Title: "Revenue Distribution by Product Category (English)"
  - [ ] Verify data displays

- [ ] **Create Tile 2: Monthly Revenue Trend**
  - [ ] Add chart → Line Chart
  - [ ] Dimension: `order_month` (date)
  - [ ] Metric: `SUM(revenue)`
  - [ ] Sort: Ascending by date
  - [ ] Add trend line
  - [ ] Title: "Monthly Revenue Trend"
  - [ ] Verify data displays

- [ ] **Add Dashboard Filters** (optional)
  - [ ] Date range filter on `order_purchase_timestamp`
  - [ ] Payment type filter on `payment_type`
  - [ ] Apply to all charts

- [ ] **Share Dashboard**
  - [ ] Click Share → Get link
  - [ ] Share with team/stakeholders
  - [ ] Enable auto-refresh: Report settings → Automatic refresh

## Phase 7: Kestra Orchestration ✓

- [ ] **Upload dbt Project to Kestra** (choose one approach)

  **Option A: Via Git**
  - [ ] Push dbt project to GitHub/GitLab
  - [ ] Record repo URL: `_________________`
  - [ ] Create Kestra secrets:
    - [ ] `GIT_USERNAME` or SSH key
    - [ ] `GIT_TOKEN` (PAT)

  **Option B: Via Namespace Files**
  - [ ] Upload dbt files to Kestra namespace
  - [ ] Or use dynamic workspace mount

- [ ] **Upload Kestra Flow**
  - [ ] Go to Kestra UI → Flows
  - [ ] Upload: `flows/olist_dbt_transformations.yml`
  - [ ] Edit flow to set:
    - [ ] `GCP_PROJECT_ID`: YOUR_PROJECT_ID
    - [ ] `notification_email`: your@email.com
    - [ ] Git repo URL (if using Git approach)

- [ ] **Set Kestra Secrets**
  - [ ] Go to Kestra UI → Secrets
  - [ ] Create secrets:
    - [ ] `GCP_SA_KEY`: Content of service account JSON
    - [ ] `GCP_PROJECT_ID`: Your project ID
  - [ ] Reference in flow: `{{ secret.GCP_SA_KEY }}`

- [ ] **Test Kestra Flow Manually**
  - [ ] Go to flow → Click "Run"
  - [ ] Monitor: Watch each task execute
  - [ ] Check logs for any errors
  - [ ] Expected: All tasks pass (green)

- [ ] **Verify dbt Artifacts in Kestra**
  - [ ] Check output: Did models get created?
  - [ ] Query: `SELECT COUNT(*) FROM olist_prod.marts.fct_sales`
  - [ ] Check: Did tests pass?
  - [ ] Review logs: Any warnings?

- [ ] **Set Up Scheduling**
  - [ ] Edit flow triggers
  - [ ] Configure cron: `0 2 * * *` (daily at 2 AM UTC)
  - [ ] Or set to manual if testing first
  - [ ] Save

- [ ] **Test Email Notifications**
  - [ ] Configure email task in Kestra:
    - [ ] From: `kestra@yourdomain.com`
    - [ ] To: `{{ secret.NOTIFICATION_EMAIL }}`
    - [ ] SMTP settings configured
  - [ ] Run flow manually
  - [ ] Check inbox for success email

## Phase 8: Monitoring & Validation ✓

- [ ] **Daily Checks**
  - [ ] [ ] Check Kestra execution log for failures
  - [ ] [ ] Query dbt test results in BigQuery
  - [ ] [ ] Check Looker Studio dashboard for data
  - [ ] [ ] Review any error notifications

- [ ] **Weekly Checks**
  - [ ] [ ] Revenue trends in dashboard
  - [ ] [ ] Any category anomalies
  - [ ] [ ] Data quality metrics
  - [ ] [ ] dbt docs still accurate

- [ ] **Validate Data Integrity**
  ```sql
  -- Total rows
  SELECT COUNT(*) as total_rows FROM olist_prod.marts.fct_sales;
  
  -- Date range
  SELECT 
    MIN(order_purchase_timestamp) as earliest,
    MAX(order_purchase_timestamp) as latest
  FROM olist_prod.marts.fct_sales;
  
  -- Revenue stats
  SELECT 
    COUNT(DISTINCT order_id) as order_count,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_revenue
  FROM olist_prod.marts.fct_sales;
  ```

- [ ] **Performance Metrics**
  - [ ] Note dbt build time: _________ minutes
  - [ ] BigQuery bytes scanned: _________ MB
  - [ ] Query performance on dashboard tiles

## Phase 9: Documentation & Handoff ✓

- [ ] **Review Documentation**
  - [ ] [ ] README.md - Overview
  - [ ] [ ] QUICKSTART.md - Getting started
  - [ ] [ ] ARCHITECTURE.md - System design
  - [ ] [ ] LOOKER_STUDIO_GUIDE.md - Dashboard setup

- [ ] **Update Team**
  - [ ] [ ] Share dashboard link with stakeholders
  - [ ] [ ] Document: Where is data sourced?
  - [ ] [ ] Document: Who can access what?
  - [ ] [ ] Document: How to request changes?

- [ ] **Create Runbooks**
  - [ ] [ ] How to run dbt manually
  - [ ] [ ] How to debug failed dbt test
  - [ ] [ ] How to refresh dashboard
  - [ ] [ ] Who to contact for issues

## Phase 10: Post-Implementation ✓

- [ ] **Monitor for 1 Week**
  - [ ] [ ] Ensure daily Kestra runs succeed
  - [ ] [ ] Dashboard displays correctly
  - [ ] [ ] No data anomalies
  - [ ] [ ] Performance acceptable

- [ ] **Iterate & Improve**
  - [ ] [ ] Gather feedback from users
  - [ ] [ ] Add new dashboards if requested
  - [ ] [ ] Optimize slow queries
  - [ ] [ ] Update dbt tests based on findings

- [ ] **Schedule Maintenance**
  - [ ] [ ] Weekly: Data quality review
  - [ ] [ ] Monthly: Performance optimization
  - [ ] [ ] Quarterly: Credential rotation
  - [ ] [ ] Yearly: Architecture review

## Troubleshooting Reference

| Issue | Checklist |
|-------|-----------|
| dbt run fails | ☐ profiles.yml correct ☐ keyfile accessible ☐ GCP perms OK ☐ datasets exist |
| No data in dashboard | ☐ dbt build succeeded ☐ marts table has rows ☐ Looker connected to correct dataset ☐ Date filters not too restrictive |
| Kestra flow fails | ☐ Git URL correct ☐ Secrets configured ☐ Service account JSON valid ☐ dbt image pulls OK |
| Tests failing | ☐ Check test output ☐ Data quality issue ☐ Run `dbt test --store-failures` ☐ Review raw data |
| Slow performance | ☐ Check dbt threads ☐ Verify partitioning applied ☐ Reduce data range ☐ Check BigQuery costs |

## Sign-Off

- [ ] **Project Complete**
  - [ ] All phases completed
  - [ ] dbt project running in production
  - [ ] Looker dashboard deployed
  - [ ] Kestra orchestration automated
  - [ ] Team trained and documentation shared

**Completion Date**: _______________  
**Completed By**: _______________  
**Notes/Issues**: _______________________________________________

---

## Quick Reference Commands

```bash
# Setup
cd olist_analytics
pip install -r requirements.txt
dbt deps

# Development
dbt run --select stg_*
dbt test --select marts.fct_sales
dbt compile

# Production
dbt run --target prod
dbt build --target prod
dbt test --target prod

# Documentation
dbt docs generate
dbt docs serve

# Debugging
dbt debug
dbt compile --select stg_orders
dbt test --select marts.fct_sales --store-failures
```

---

**Status**: Ready for implementation  
**Last Updated**: April 2026
