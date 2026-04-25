# Olist Pipeline Architecture

Complete documentation of the Olist ecommerce analytics pipeline architecture.

## System Overview

```
┌────────────────────────────────────────────────────────────────┐
│                    OLIST ANALYTICS PIPELINE                     │
│                    (Orchestrated by Kestra)                     │
└────────────────────────────────────────────────────────────────┘

  ┌──────────────────┐
  │  Raw Data        │
  │  (Kaggle CSV)    │
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────┐
  │  BigQuery Raw    │        ┌─────────────────────┐
  │  Dataset (raw)   │◄──────┤  Kestra Task 1      │
  │  - orders        │        │  Load/Ingest CSV    │
  │  - order_items   │        │  (Optional)         │
  │  - products      │        └─────────────────────┘
  │  - payments      │
  │  - category xref │
  └────────┬─────────┘
           │
           ▼
  ┌─────────────────────────┐
  │  dbt Staging Layer      │      ┌──────────────────────┐
  │  (Views - stg_*)        │◄─────┤  Kestra Task 2      │
  │  - stg_orders           │      │  Run dbt Models      │
  │  - stg_order_items      │      │  (deps, run, test)   │
  │  - stg_payments         │      └──────────────────────┘
  │  - stg_products         │
  │  (Clean, standardize)   │
  └────────┬────────────────┘
           │
           ▼
  ┌─────────────────────────────────────┐
  │  dbt Marts Layer                    │
  │  (Tables - fct_sales)               │
  │  - Partitioned by order_month       │
  │  - Clustered by category, payment   │
  │  - Tests: not_null, unique, etc     │
  │  - Grain: one row per order item    │
  │  - Filters: delivered/shipped only  │
  └────────┬────────────────────────────┘
           │
           ▼
  ┌────────────────────────────────────┐
  │  Looker Studio Dashboard           │
  │  ┌──────────────────────────────┐  │
  │  │ Revenue by Category (Bar)    │  │
  │  │ - Top 15 categories          │  │
  │  │ - SUM(revenue) by category   │  │
  │  └──────────────────────────────┘  │
  │  ┌──────────────────────────────┐  │
  │  │ Monthly Revenue Trend (Line) │  │
  │  │ - Time series from 2016-2018 │  │
  │  │ - SUM(revenue) by month      │  │
  │  └──────────────────────────────┘  │
  └────────────────────────────────────┘
```

## Data Flow Details

### Stage 1: Raw Data Ingestion

**Source**: Kaggle Olist Brazilian E-Commerce Dataset  
**Location**: `raw.olist_*` tables in BigQuery  
**Status**: Tables assumed to already be loaded (can add Kestra ingest task)

**Tables**:
- `raw.olist_orders_dataset` (99k rows)
- `raw.olist_order_items_dataset` (112k rows)
- `raw.olist_products_dataset` (32k rows)
- `raw.olist_order_payments_dataset` (103k rows)
- `raw.product_category_name_translation` (71 categories)

### Stage 2: dbt Staging Layer

**Purpose**: Clean, standardize, and prepare raw data  
**Materialization**: Views (no storage overhead)  
**Schema**: `stg` (configurable)

**Models**:

1. **stg_orders.sql**
   - Selects essential order columns
   - Filters for non-null purchase timestamps
   - Output: One row per order

2. **stg_order_items.sql**
   - Gets item-level details (price, freight)
   - Casts to proper types (price → FLOAT64)
   - Output: One row per order item

3. **stg_payments.sql**
   - Aggregates payments by order + payment type
   - Handles multiple payment methods per order
   - Output: One row per order-payment_type combination

4. **stg_products.sql**
   - Joins with category translation table
   - Maps Portuguese → English category names
   - Output: One row per product

### Stage 3: dbt Marts Layer

**Purpose**: Create analytics-ready fact tables for BI  
**Materialization**: Materialized table (persisted)  
**Schema**: `marts`  
**Performance Optimizations**:
- **Partitioning**: `order_month` (DATE_TRUNC by month)
- **Clustering**: `product_category_name_english`, `payment_type`

**Model: fct_sales**

- **Grain**: One row per order item (not aggregated)
- **Joins**: Combines all staging models
  - Order_items ← (Orders, Products, Payments)
- **Filters**:
  - Only 'delivered' and 'shipped' orders (meaningful sales)
  - Price > 0 (exclude edge cases)
  - Date range: 2016-01-01 to 2018-12-31
- **Metrics**:
  - `revenue = price + freight_value` (total item cost)
  - `payment_value` (total payment for order)
- **Dimensions**:
  - Order: order_id, order_purchase_timestamp, order_month, customer_id
  - Product: product_id, category (English + Portuguese)
  - Payment: payment_type
  - Timing: approved, delivered, estimated dates

### Stage 4: BI Dashboard

**Tool**: Looker Studio  
**Data Source**: `marts.fct_sales`  
**Update Cadence**: Daily (after dbt pipeline completes)

**Tile 1: Revenue Distribution by Product Category**
- Chart type: Horizontal bar
- Dimension: `product_category_name_english`
- Metric: `SUM(revenue)`
- Sort: Descending by revenue
- Shows: Top 15 categories + Others bucket

**Tile 2: Monthly Revenue Trend**
- Chart type: Line
- Dimension: `order_month` (DATE)
- Metric: `SUM(revenue)`
- Trend line: Optional (shows growth trajectory)
- Span: 2016-2018 (full dataset timeline)

## Orchestration: Kestra Flow

**Flow File**: `flows/olist_dbt_transformations.yml`  
**Trigger**: Daily at 2 AM UTC (configurable)  
**Runtime**: ~10-15 minutes (depends on data size)

### Tasks

1. **clone_dbt_project** (Optional)
   - Git clone or pull latest dbt project
   - Ensures always running latest models
   - Can skip if dbt files are in Kestra namespace

2. **dbt_deps**
   - Install dbt packages from `packages.yml`
   - Downloads: dbt-utils, audit-helper
   - Runtime: ~30 seconds

3. **run_dbt_transformations**
   - Executes: `dbt build --select stg_* marts.fct_sales`
   - Runs all staging models + marts
   - Tests during build (fail fast if test fails)
   - Timeout: 30 minutes
   - Threads: 4 (can increase for production)

4. **run_dbt_tests**
   - Executes: `dbt test --select marts.fct_sales`
   - Validates: not_null, unique, relationships, accepted_values
   - Flags: Any test failures
   - Optional: Can fail task on test failure

5. **generate_dbt_docs**
   - Generates lineage graph
   - Creates model/column documentation
   - Publishes to dbt Cloud (optional)

6. **success_notification**
   - Email sent to analytics team
   - Includes: Execution ID, duration, link to logs
   - Only if all tasks succeed

### Error Handling

- **onFailure**: Triggers failure notification email
- **Conditional tasks**: Can skip steps based on conditions
- **Retry logic**: Auto-retry failed dbt models (configurable)

## Configuration & Variables

### Environment Variables

```yaml
GCP_PROJECT_ID: your-project-id           # BigQuery project
GCP_DATASET_RAW: raw                       # Raw data schema
GCP_DATASET_DEV: olist_dev                 # Dev schema
GCP_DATASET_PROD: olist_prod               # Prod schema
DBT_PROFILES_DIR: /path/to/profiles        # Config location
DBT_THREADS: 4                             # Parallel threads
START_DATE: 2016-01-01                     # Data range start
END_DATE: 2018-12-31                       # Data range end
```

### dbt Variables

Defined in `dbt_project.yml`:
- `start_date`: Filter data from this date onward
- `end_date`: Filter data up to this date
- `orders_table`: Source table name (customizable)
- `products_table`: Source table name (customizable)
- etc.

Usage in models:
```sql
WHERE order_purchase_timestamp >= TIMESTAMP('{{ var("start_date") }}')
```

## Testing & Quality Assurance

### dbt Tests

**Schema Tests** (YAML-defined):
- `not_null`: Ensure critical fields have values
- `unique`: Validate primary keys are unique
- `relationships`: Check foreign key integrity
- `accepted_values`: Restrict to valid values

**Custom Tests** (in `tests/custom_tests.sql`):
- `revenue_positive`: Ensure revenue >= 0
- `no_future_orders`: Dates not in future

**Example**:
```yaml
tests:
  - not_null
  - unique
  - relationships:
      to: source('raw', 'olist_orders_dataset')
      field: order_id
```

### Test Coverage

| Model | Tests |
|-------|-------|
| stg_orders | not_null (order_id), unique (order_id), not_null (customer_id) |
| stg_order_items | not_null (order_id), not_null (product_id), range (price >= 0) |
| stg_payments | not_null (order_id), payment_type in values |
| stg_products | unique (product_id), not_null (category), relationships |
| fct_sales | all above, revenue_positive, no_future_orders |

### Running Tests

```bash
# All tests
dbt test

# Specific model
dbt test --select marts.fct_sales

# Fail fast on first error
dbt test --fail-fast

# See test output
dbt test --select marts.fct_sales --store-failures
```

## Deployment Strategies

### Development Workflow

```
Local machine:
  1. dbt run --target dev (creates dev dataset)
  2. dbt test (validates quality)
  3. dbt docs serve (review changes)
  4. Git commit & push
```

### Production Workflow

```
Kestra orchestration:
  1. Daily trigger at 2 AM UTC
  2. Git pull latest code
  3. dbt build --target prod (runs + tests)
  4. Email notification
  5. Looker Studio auto-refreshes
```

### Release Process

1. **Test locally**:
   ```bash
   dbt run --target dev
   dbt test
   ```

2. **Git version control**:
   ```bash
   git commit -m "Add new model: dim_customers"
   git push origin feature/dim-customers
   ```

3. **Code review** (if team shared)

4. **Merge to main** & Kestra auto-picks up

5. **Monitor in Kestra**: Check logs & test results

## Scaling & Performance

### Current State (Analysis)

- **Data volume**: ~200k base records (orders, items, payments)
- **dbt runtime**: ~2-5 minutes
- **Materialization**: Staging = views, Marts = table
- **Partitioning**: By order_month (30 partitions for 2016-2018)

### If Growing (Optimization Tips)

1. **Increase dbt threads**: `DBT_THREADS: 8` in Kestra
2. **Add incremental models**: Track only new/changed data
3. **Enable dbt benchmarking**: `--debug` flag shows model times
4. **Optimize clustering**: Add more columns if common filters change
5. **Archive old data**: Move pre-2017 data to cold storage

### BigQuery Cost Optimization

- **Use views for staging**: No storage costs
- **Partition fact tables**: Scan only needed months
- **Cluster wisely**: By column used in filters
- **Bytes scanned**: Monitor with Kestra logs
- **Reserved slots**: For predictable production workload

## Security & Access Control

### Service Account Permissions

**Required roles**:
- `roles/bigquery.dataEditor` - Read/Write datasets
- `roles/bigquery.jobUser` - Submit queries

**Recommended**:
- Create specific SA for dbt (not broad admin)
- Rotate credentials quarterly
- Use Kestra secrets, not hardcoded

### Credential Management

```yaml
# In Kestra secrets (encrypted):
GCP_SA_KEY: <service-account-json>
GCP_PROJECT_ID: <project-id>

# Not in code:
profiles.yml  # Add to .gitignore
gcp-sa-key.json
.env
```

## Monitoring & Alerting

### Kestra Built-in Monitoring

- **Execution logs**: Full task output (searchable)
- **Failure notifications**: Email on error
- **Execution timeline**: See duration per task
- **Test results**: Pass/fail counts

### Recommended Alerts

1. **dbt build failure**: Instant email
2. **Tests failing**: Investigation required
3. **Slow execution**: >30 min runtime
4. **No data in marts**: Data quality issue
5. **Dashboard not refreshing**: Check pipeline status

### Manual Checks

```sql
-- Is data flowing?
SELECT COUNT(*) FROM marts.fct_sales;

-- Latest data?
SELECT MAX(order_purchase_timestamp) FROM marts.fct_sales;

-- Any nulls?
SELECT * FROM marts.fct_sales WHERE revenue IS NULL;

-- Test results?
-- Check dbt test output in Kestra logs
```

## Troubleshooting Guide

| Issue | Cause | Solution |
|-------|-------|----------|
| "Table not found" | Raw data not loaded | Load Olist dataset to BigQuery first |
| dbt fails silently | Missing variables | Check `dbt_project.yml` vars defined |
| Slow performance | Full data scan | Check partitioning/clustering applied |
| Dashboard blank | Stale connection | Re-authorize in Looker Studio |
| Test failures | Data quality issue | Run `dbt test --store-failures` to debug |

## Maintenance Tasks

### Weekly

- [ ] Check Looker Studio dashboard for anomalies
- [ ] Review Kestra execution logs
- [ ] Monitor any test failures

### Monthly

- [ ] Review dbt model documentation
- [ ] Check BigQuery data volume & costs
- [ ] Update categories/dimensions if needed

### Quarterly

- [ ] Rotate GCP service account credentials
- [ ] Review & optimize slow models
- [ ] Audit data quality metrics

## Future Enhancements

1. **Incremental models**: Only process new orders daily
2. **Dimension tables**: Add `dim_customers`, `dim_sellers`
3. **More dashboards**: Customer LTV, seller performance, product trends
4. **Alerts**: Anomaly detection on revenue spikes/drops
5. **dbt tests**: Add macro-based freshness checks
6. **Reverse ETL**: Sync insights back to operational systems

## References

- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [BigQuery Architecture](https://cloud.google.com/bigquery/docs/best-practices)
- [Kestra Documentation](https://kestra.io/docs)
- [Looker Studio Guide](./LOOKER_STUDIO_GUIDE.md)

---

**Version**: 1.0  
**Last Updated**: April 2026  
**Maintained by**: Data Analytics Team
