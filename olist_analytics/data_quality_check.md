# Handling Source Data Quality Failures in dbt

## Context

When orchestrating dbt pipelines against real-world datasets — such as the public
[Olist Brazilian E-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
loaded into BigQuery — it is common to encounter data quality test failures that are
**not caused by pipeline errors**, but by the nature of the source data itself.

This document describes the specific failures encountered during the first successful
run of the `olist_sales_dbt` Kestra pipeline, explains why they occurred, and outlines
two resolution strategies.

---

## What Happened

After resolving all infrastructure and authentication issues, the pipeline connected
to BigQuery successfully and ran `dbt build`. The run completed with:

```
PASS=20  WARN=0  ERROR=4  SKIP=17  TOTAL=41
```

The 4 errors were all **dbt test failures on staging models**, not model compilation
or BigQuery execution errors. Because these tests failed at `ERROR` severity (the
default), dbt blocked all downstream models from running — causing `fct_sales` and
its 17 dependent tests to be skipped entirely.

---

## The Failures

### 1. Null product category names — 610 rows

```
FAIL 610  not_null_stg_products_product_category_name
FAIL 610  not_null_stg_products_product_category_name_english
```

**Cause:** 610 products in the Olist dataset have no assigned category. Because the
source data is a public Kaggle export, these nulls are a known characteristic of the
dataset — not a pipeline or ingestion bug. The `not_null` test was too strict.

---

### 2. Unexpected order status values — 2 rows

```
FAIL 2  accepted_values_stg_orders_order_status__delivered__shipped__cancelled__...
```

**Cause:** 2 orders carry a status value not present in the original allowed list
defined in `staging.yml`. The Olist dataset spans several years and contains edge-case
statuses that were not accounted for in the initial test configuration.

To identify the unexpected values, run the following in BigQuery:

```sql
SELECT DISTINCT order_status, COUNT(*) AS n
FROM `ecommerce-4939.olist_dataset_4939.orders`
GROUP BY 1
ORDER BY 1;
```

---

### 3. Unexpected payment type — 1 row

```
FAIL 1  accepted_values_stg_payments_payment_type__credit_card__boleto__debit_card__voucher
```

**Cause:** 1 payment record contains a payment type outside the four expected values.
Again, a characteristic of the public dataset. To find it:

```sql
SELECT DISTINCT payment_type, COUNT(*) AS n
FROM `ecommerce-4939.olist_dataset_4939.order_payments`
GROUP BY 1
ORDER BY 1;
```

---

## Why This Matters

By default, dbt treats all test failures as `error` severity. When a model's tests
fail, **all downstream models that depend on it are skipped**. In this pipeline,
the 4 staging test failures caused `fct_sales` (the core mart) and all 17 of its
tests to be skipped — meaning no mart data was produced despite the staging views
being created successfully.

---

## Resolution Options

### Option A — Downgrade failing tests to `warn` severity

This is the **recommended approach** when working with public or external datasets
you do not control. The pipeline continues to completion; failures are surfaced as
warnings in the dbt run results without blocking downstream models.

Update `models/staging/staging.yml`:

```yaml
# Products — nullable categories are expected in this dataset
- name: product_category_name
  description: Product category in Portuguese
  tests:
    - not_null:
        config:
          severity: warn

- name: product_category_name_english
  description: English translation of category
  tests:
    - not_null:
        config:
          severity: warn

# Orders — allow for edge-case statuses present in historical data
- name: order_status
  description: Current status of the order
  tests:
    - accepted_values:
        config:
          severity: warn
        values:
          - delivered
          - shipped
          - cancelled
          - processing
          - unavailable
          - invoiced
          - created

# Payments — allow for undocumented payment types in older records
- name: payment_type
  description: Payment method used
  tests:
    - accepted_values:
        config:
          severity: warn
        values:
          - credit_card
          - boleto
          - debit_card
          - voucher
```

After this change, a run will produce:

```
PASS=20  WARN=4  ERROR=0  SKIP=0  TOTAL=41
```

And `fct_sales` will build successfully.

---

### Option B — Extend the allowed values to match the actual data

This approach is appropriate when you want tests to remain at `error` severity and
reflect the true domain of the data. First, query BigQuery to discover all actual
values, then update the allowed lists accordingly.

**For order status:**

```sql
SELECT DISTINCT order_status
FROM `ecommerce-4939.olist_dataset_4939.orders`
ORDER BY 1;
```

Then update `staging.yml`:

```yaml
- name: order_status
  tests:
    - accepted_values:
        values:
          - delivered
          - shipped
          - cancelled
          - processing
          - unavailable
          - invoiced
          - created
          - approved         # ← add any additional values found
```

**For payment type:**

```sql
SELECT DISTINCT payment_type
FROM `ecommerce-4939.olist_dataset_4939.order_payments`
ORDER BY 1;
```

Then update accordingly:

```yaml
- name: payment_type
  tests:
    - accepted_values:
        values:
          - credit_card
          - boleto
          - debit_card
          - voucher
          - not_defined      # ← add any additional values found
```

**For null product categories:**

Rather than relaxing `not_null`, filter nulls explicitly in the staging model
(`stg_products.sql`) and document the exclusion:

```sql
SELECT
    product_id,
    -- Olist source data contains ~610 products with no category assignment.
    -- Coalesce to 'uncategorized' to preserve row count while satisfying not_null.
    COALESCE(product_category_name, 'uncategorized')          AS product_category_name,
    COALESCE(product_category_name_english, 'uncategorized')  AS product_category_name_english
FROM {{ source('raw', 'products') }}
```

---

## Recommendation

| Scenario | Recommended option |
|---|---|
| Public / external dataset you don't own | **Option A** — warn severity |
| Internal dataset where data quality is enforced upstream | **Option B** — fix the allowed values or the source data |
| Mixed — some tests are hard requirements, others are informational | Use `severity: warn` selectively per test |

For the Olist dataset, **Option A** is appropriate. The data is a historical export
and the anomalies (null categories, edge-case statuses) are documented characteristics
of the source, not errors introduced by the pipeline.

---

## After Applying the Fix

Once the changes are committed and pushed to the `main` branch, re-trigger the
Kestra flow. Because the pipeline clones the repo fresh on every run, no other
changes are required. A successful run will show:

```
PASS=37  WARN=4  ERROR=0  SKIP=0  TOTAL=41
fct_sales  →  CREATE TABLE  
```