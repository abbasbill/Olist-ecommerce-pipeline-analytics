# Olist Analytics - dbt Project

This dbt project transforms raw Olist ecommerce data into clean, analytics-ready tables in BigQuery. It focuses on sales performance analysis with staging models for data cleanup and marts for business intelligence.

## Project Overview

**Data Source**: Kaggle Olist Brazilian E-Commerce Dataset  
**Warehouse**: Google BigQuery  
**Orchestration**: Kestra  
**BI Tool**: Looker Studio  

### Key Features

- **Staging Layer** (`stg_*`): Clean and standardize raw data
  - `stg_orders`: Order metadata and timestamps
  - `stg_order_items`: Item-level sales details
  - `stg_payments`: Payment methods and amounts
  - `stg_products`: Product information with English category translations

- **Marts Layer** (`marts.fct_sales`): Fact table for sales analytics
  - Combines all sales dimensions
  - Partitioned by `order_month` for performance
  - Clustered by category and payment type
  - Includes revenue metrics (price + freight)

## Setup

### Prerequisites

- dbt >= 1.0
- Python >= 3.8
- GCP service account with BigQuery access
- Kestra (for orchestration)

### Installation

1. **Install dbt and dependencies**:
   ```bash
   pip install dbt-bigquery
   cd olist_analytics
   dbt deps
   ```

2. **Configure credentials**:
   ```bash
   # Create GCP service account and download key
   export DBT_PROFILES_DIR=$PWD
   
   # Update profiles.yml with your GCP project ID and keyfile path
   nano profiles.yml
   ```

3. **Test the connection**:
   ```bash
   dbt debug
   ```

## Running dbt

### Development

```bash
# Run all models
dbt run

# Run specific model
dbt run --select stg_orders

# Run with full refresh
dbt run --full-refresh
```

### Testing

```bash
# Run all tests
dbt test

# Run specific test
dbt test --select marts.fct_sales
```

### Documentation

```bash
# Generate and serve docs
dbt docs generate
dbt docs serve
```

### Production Build

```bash
# Full build (run + test)
dbt build --select stg_* marts.fct_sales
```

## Kestra Integration

Add this task to your Kestra flow to run dbt transformations:

```yaml
- id: run_dbt_transformations
  type: io.kestra.plugin.dbt.cli.DbtCLI
  taskRunner:
    type: io.kestra.plugin.scripts.runner.docker.Docker
  containerImage: ghcr.io/kestra-io/dbt-bigquery:latest
  projectDir: /path/to/olist_analytics
  commands:
    - dbt deps
    - dbt build --select stg_* marts.fct_sales
    - dbt test
  env:
    DBT_PROFILES_DIR: /path/to/profiles
```

## Project Structure

```
olist_analytics/
├── dbt_project.yml          # dbt configuration
├── profiles.yml             # Connection config (not committed)
├── packages.yml             # dbt package dependencies
├── README.md                # This file
├── models/
│   ├── sources.yml          # Raw data source definitions
│   ├── staging/
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_payments.sql
│   │   ├── stg_products.sql
│   │   └── staging.yml      # Tests and documentation
│   └── marts/
│       ├── fct_sales.sql    # Core fact table
│       └── marts.yml        # Tests and documentation
├── tests/                   # Custom dbt tests
├── macros/                  # Jinja2 macros for reusable code
└── seeds/                   # Static reference data (if any)
```

## Key Transformations

### Staging Models

- **stg_orders**: Selects order ID, purchase timestamp, and status from raw orders
- **stg_order_items**: Gets item-level details (quantity, price, freight)
- **stg_payments**: Aggregates payments by order (one row per payment method per order)
- **stg_products**: Joins raw products with English category translation

### Marts - fct_sales

Central fact table combining:
- Order context (ID, timestamp, status)
- Product details (category, name length)
- Financial metrics (price, freight, total revenue)
- Payment type

**Filters**: Only includes delivered and shipped orders

**Partitioning**: By `order_month` (DATE_TRUNC of purchase timestamp)  
**Clustering**: By `product_category_name_english` and `payment_type`

## Looker Studio Dashboards

The marts data supports two key analytics tiles:

1. **Revenue Distribution by Product Category**: Horizontal bar chart of total revenue by English product category
2. **Monthly Revenue Trend**: Line chart of SUM(revenue) by month showing seasonality and growth

## Testing & Quality

Tests are defined in YAML schema files:
- **not_null**: Ensures critical fields have values
- **unique**: Validates primary keys
- **relationships**: Checks referential integrity
- **custom tests**: Business logic validation

View test results:
```bash
dbt test --select marts.fct_sales
```

## Documentation

Generate dbt documentation:
```bash
dbt docs generate
dbt docs serve  # Opens at http://localhost:8000
```

## Contributing

1. Create a new branch for changes
2. Test locally before committing
3. Ensure all tests pass: `dbt test`
4. Update documentation in YAML files
5. Create a pull request

## Support

For issues or questions:
- Check dbt [documentation](https://docs.getdbt.com)
- Review [BigQuery adapter docs](https://docs.getdbt.com/reference/warehouse-setups/bigquery-setup)
- Check Kestra [dbt plugin docs](https://kestra.io/plugins/io.kestra.plugin.dbt)
