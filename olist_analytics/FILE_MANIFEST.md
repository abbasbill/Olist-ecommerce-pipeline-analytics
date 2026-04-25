# dbt Project Structure - Complete File Manifest

Complete listing of all files in the Olist dbt project with descriptions.

## 📁 Directory Structure

```
olist_analytics/
├── Configuration Files (Root Level)
│   ├── dbt_project.yml              # dbt project config (materialization, schemas, variables)
│   ├── profiles.yml                 # BigQuery connection config (NOT committed to git)
│   ├── packages.yml                 # dbt dependencies (dbt-utils, audit-helper)
│   ├── requirements.txt              # Python dependencies (dbt-bigquery, etc.)
│   ├── .gitignore                   # Files to exclude from git
│   └── .env.example                 # Template for environment variables
│
├── Documentation Files
│   ├── README.md                    # Project overview & setup guide
│   ├── QUICKSTART.md                # 10-minute quick start guide
│   ├── ARCHITECTURE.md              # Complete system architecture
│   ├── LOOKER_STUDIO_GUIDE.md       # Dashboard setup instructions
│   ├── IMPLEMENTATION_CHECKLIST.md  # Step-by-step implementation guide
│   └── FILE_MANIFEST.md             # This file
│
├── models/                          # dbt model definitions
│   ├── sources.yml                  # Raw data source definitions & tests
│   │
│   ├── staging/                     # Staging layer (views)
│   │   ├── stg_orders.sql           # Order-level data cleanup
│   │   ├── stg_order_items.sql      # Item-level sales details
│   │   ├── stg_payments.sql         # Payment aggregation by order
│   │   ├── stg_products.sql         # Product data with translation
│   │   └── staging.yml              # Tests & documentation for staging
│   │
│   └── marts/                       # Marts layer (tables)
│       ├── fct_sales.sql            # Core fact table for sales analytics
│       └── marts.yml                # Tests & documentation for marts
│
├── tests/                           # dbt test definitions
│   └── custom_tests.sql             # Custom test macros (revenue_positive, no_future_orders)
│
├── macros/                          # Jinja2 macros for reusable code
│   └── generate_alias_name.sql      # Custom macros (aliases, revenue calculation, permissions)
│
├── seeds/                           # Static reference data
│   └── (empty - ready for seed CSVs)
│
├── snapshots/                       # Historical tracking
│   └── (empty - ready for snapshot configs)
│
└── setup.sh                         # Setup script to install dependencies
```

## 📄 File Descriptions

### Configuration Files

#### `dbt_project.yml`
- **Purpose**: Core dbt configuration
- **Contains**: 
  - Project name: `olist_analytics`
  - Model materialization: staging = views, marts = tables
  - BigQuery-specific settings: partitioning, clustering, schema names
  - Global variables: start_date, end_date, table names
- **Key Settings**:
  - `profile: 'olist_analytics'` → Matches profiles.yml
  - `+partition_by: order_month` → Fact table partitioned by month
  - `+cluster_by: [product_category_name_english, payment_type]` → Clustered for fast queries

#### `profiles.yml` ⚠️ (DO NOT COMMIT)
- **Purpose**: BigQuery connection configuration
- **Contains**: 
  - GCP project ID
  - Service account keyfile path
  - Dev & prod targets with different datasets
  - Number of threads per environment
- **Security**: Add to .gitignore, use Kestra secrets in production
- **Setup**: Fill in your values before running dbt

#### `packages.yml`
- **Purpose**: External dbt package dependencies
- **Contains**:
  - `dbt-labs/dbt_utils` → Generic macros for common operations
  - `dbt-labs/audit_helper` → Tools for dbt debugging
- **Usage**: Run `dbt deps` to install

#### `requirements.txt`
- **Purpose**: Python package dependencies
- **Contains**:
  - `dbt-bigquery==1.5.3` → BigQuery adapter for dbt
  - `dbt-core==1.5.3` → Core dbt framework
  - `dbt-utils==1.0.0` → Utility functions
- **Usage**: `pip install -r requirements.txt`

#### `.gitignore`
- **Purpose**: Files to exclude from git version control
- **Contains**: dbt target folder, logs, profiles.yml, credentials, IDE files, __pycache__, etc.
- **Critical**: Ensures secrets are never committed

#### `.env.example`
- **Purpose**: Template for environment variables
- **Usage**: Copy to `.env`, fill in your values
- **Contains**: GCP project ID, dataset names, Kestra config, date ranges

### Documentation Files

#### `README.md`
- **Purpose**: Project overview and main entry point
- **Sections**:
  - Project overview
  - Setup instructions
  - Running dbt commands
  - Kestra integration
  - Project structure
  - Testing & documentation
  - Contributing guidelines
- **Audience**: All team members

#### `QUICKSTART.md`
- **Purpose**: Get started in 10 minutes
- **Sections**:
  - Prerequisites
  - Local setup (install + config)
  - Running models (dev & prod)
  - Testing
  - Documentation
  - Kestra integration
  - Troubleshooting
  - Common commands reference
- **Audience**: New users, developers

#### `ARCHITECTURE.md`
- **Purpose**: Complete system design documentation
- **Sections**:
  - System overview (data flow diagram)
  - Data flow details (raw → stg → marts)
  - Orchestration (Kestra flow breakdown)
  - Configuration & variables
  - Testing & QA strategy
  - Deployment strategies
  - Performance & scaling
  - Security & access control
  - Monitoring & alerting
  - Troubleshooting guide
  - Maintenance tasks
  - Future enhancements
- **Audience**: Data engineers, architects

#### `LOOKER_STUDIO_GUIDE.md`
- **Purpose**: Create analytics dashboards
- **Sections**:
  - Dashboard overview
  - BigQuery connection setup
  - Tile 1: Revenue by Category (horizontal bar chart)
  - Tile 2: Monthly Revenue Trend (line chart)
  - Layout recommendations
  - Filters to add
  - Sharing & collaboration
  - Common issues & troubleshooting
  - KPIs to monitor
- **Audience**: Business analysts, dashboard creators

#### `IMPLEMENTATION_CHECKLIST.md`
- **Purpose**: Step-by-step implementation guide
- **Sections**:
  - 10 phases from setup to production
  - Checkbox items for tracking progress
  - Commands to run
  - Validation queries
  - Post-implementation monitoring
  - Sign-off section
- **Audience**: Project managers, implementers

### Data Models

#### `models/sources.yml`
- **Purpose**: Define raw data source tables in BigQuery
- **Contains**: 
  - 5 source tables (orders, items, products, payments, translation)
  - Column descriptions & data types
  - Source tests (not_null, unique, relationships, accepted_values)
  - Example: `olist_orders_dataset` with 8 columns
- **Usage**: Referenced in staging models via `{{ source('raw', 'table_name') }}`

#### `models/staging/stg_orders.sql`
- **Purpose**: Clean order-level data
- **Output**: One row per order
- **Operations**: Select essential columns, filter for non-null timestamps
- **Materialization**: View (no storage)
- **Tests**: Defined in staging.yml

#### `models/staging/stg_order_items.sql`
- **Purpose**: Clean item-level sales data
- **Output**: One row per order item
- **Operations**: Select item columns, cast price/freight to FLOAT64
- **Filters**: Where price IS NOT NULL
- **Tests**: not_null, price >= 0

#### `models/staging/stg_payments.sql`
- **Purpose**: Aggregate payment data by order + payment type
- **Output**: One row per order-payment_type combo
- **Aggregation**: SUM(payment_value), count(payment_sequential)
- **Handles**: Multiple payment methods per order

#### `models/staging/stg_products.sql`
- **Purpose**: Product data with English category translation
- **Output**: One row per product
- **Join**: Products LEFT JOIN category_translation (Portuguese → English)
- **Columns**: Product dimensions (name length, description length, weight, dimensions)

#### `models/staging/staging.yml`
- **Purpose**: Schema definitions, tests, and documentation for staging models
- **Contains**:
  - 4 model definitions (stg_orders, stg_order_items, stg_payments, stg_products)
  - Column descriptions
  - Tests: not_null, unique, relationships, accepted_values, range
  - Data quality constraints
- **Example**: stg_payments tests that payment_type is in ['credit_card', 'boleto', ...]

#### `models/marts/fct_sales.sql`
- **Purpose**: Core fact table for sales analytics
- **Grain**: One row per order item (not aggregated)
- **Joins**: Combines orders + items + products + payments
- **Materialization**: TABLE (persisted in BigQuery)
- **Optimization**:
  - Partition by: `order_month` (30 partitions for 2016-2018)
  - Cluster by: `product_category_name_english`, `payment_type`
- **Filters**:
  - Only 'delivered' and 'shipped' orders
  - Price > 0
  - Date range: 2016-01-01 to 2018-12-31
- **Metrics**: revenue = price + freight_value
- **Columns**: 22 columns combining order, product, payment, and timing data

#### `models/marts/marts.yml`
- **Purpose**: Schema definitions, tests, and documentation for marts
- **Contains**:
  - 1 model definition (fct_sales)
  - 20 column descriptions
  - Tests: not_null, unique, relationships, range, recency
  - Data quality checks
  - Example: revenue tested for >= 0, timestamps tested for not in future
- **Recency Test**: Ensures data is fresh (updated within last 365 days)

### Tests

#### `tests/custom_tests.sql`
- **Purpose**: Custom dbt test macros
- **Contains**:
  1. `revenue_positive`: Test that revenue >= 0 (no negative values)
  2. `no_future_orders`: Test that order dates are not in future
- **Usage**: Called from .yml files via `test_name: revenue_positive`
- **Example**: Applied to fct_sales.revenue column

### Macros

#### `macros/generate_alias_name.sql`
- **Purpose**: Reusable Jinja2 code for dbt
- **Macros**:
  1. `generate_alias_name`: Custom table naming (can be customized)
  2. `calculate_revenue`: Macro to compute price + freight (reusable)
  3. `grant_permissions`: Macro to grant BigQuery access (optional, for security)
- **Usage**: Call in models with `{{ calculate_revenue('price_col', 'freight_col') }}`

### Scripts

#### `setup.sh`
- **Purpose**: Automated setup script
- **Contains**: Commands to install dependencies, run dbt deps, test connection
- **Usage**: `bash setup.sh`
- **Output**: Ready-to-use dbt project

### Kestra Integration

#### `flows/olist_dbt_transformations.yml` (in main project flows/)
- **Purpose**: Kestra orchestration workflow
- **Tasks**:
  1. clone_dbt_project (optional Git pull)
  2. dbt_deps (install packages)
  3. run_dbt_transformations (build models)
  4. run_dbt_tests (validate data)
  5. generate_dbt_docs (documentation)
  6. success_notification (email alert)
- **Trigger**: Daily at 2 AM UTC (configurable)
- **Error Handling**: onFailure task sends failure notification
- **Runtime**: ~10-15 minutes

## 📊 File Count Summary

| Category | Count | Purpose |
|----------|-------|---------|
| Configuration | 6 | Project setup, connection, dependencies |
| Documentation | 6 | Guides, architecture, implementation |
| SQL Models | 5 | Data transformations (staging + marts) |
| YAML Schemas | 3 | Tests, documentation, metadata |
| Tests | 1 | Custom test macros |
| Macros | 1 | Reusable code |
| Scripts | 1 | Setup automation |
| **Total** | **23** | Complete dbt project |

## 🔄 Data Flow Through Files

```
sources.yml (define raw data)
    ↓
stg_*.sql (clean data)
    ↓
staging.yml (test staging)
    ↓
fct_sales.sql (join all sources)
    ↓
marts.yml (test marts)
    ↓
Looker Studio (visualize)
    ↓
Dashboard KPIs
```

## 🚀 Getting Started Path

1. **Start here**: README.md
2. **Quick setup**: QUICKSTART.md (10 minutes)
3. **Understand system**: ARCHITECTURE.md
4. **Implement step-by-step**: IMPLEMENTATION_CHECKLIST.md
5. **Create dashboard**: LOOKER_STUDIO_GUIDE.md
6. **Reference models**: models/staging/*.sql, models/marts/fct_sales.sql
7. **Run tests**: QUICKSTART.md testing section

## 📝 Key Files by Role

### For Data Engineers
- `dbt_project.yml` - Configuration
- `models/staging/*.sql` - Model development
- `tests/custom_tests.sql` - Test creation
- `macros/*.sql` - Code reuse

### For Analysts
- `models/marts/fct_sales.sql` - Available data
- `marts.yml` - Column documentation
- `LOOKER_STUDIO_GUIDE.md` - Dashboard creation

### For DevOps/Orchestration
- `profiles.yml` - Connection config
- `flows/olist_dbt_transformations.yml` - Kestra flow
- `requirements.txt` - Dependencies

### For Project Managers
- `IMPLEMENTATION_CHECKLIST.md` - Rollout plan
- `ARCHITECTURE.md` - System overview
- `README.md` - Project summary

## 🔐 Security Considerations

**Never commit to git**:
- ❌ profiles.yml (has keyfile path)
- ❌ gcp-sa-key.json (credentials)
- ❌ .env (secrets)

**Always in .gitignore**:
- ✓ target/
- ✓ dbt_packages/
- ✓ logs/
- ✓ profiles.yml
- ✓ .env
- ✓ IDE folders

**Use Kestra secrets for production**:
- Store GCP_SA_KEY in Kestra secrets vault
- Reference via `{{ secret.GCP_SA_KEY }}`
- Rotate credentials quarterly

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| dbt-core | 1.5.3 | Core dbt framework |
| dbt-bigquery | 1.5.3 | BigQuery adapter |
| dbt-utils | 1.0.0 | Generic macros |
| audit-helper | 0.7.0 | dbt debugging tools |

## 🎯 Project Status

- ✅ Core dbt project structure
- ✅ Staging layer (4 models)
- ✅ Marts layer (1 fact table)
- ✅ Tests & documentation
- ✅ Kestra orchestration example
- ✅ Looker Studio guide
- ✅ Implementation checklist
- ✅ Architecture documentation

Ready for immediate implementation!

---

**Version**: 1.0  
**Created**: April 2026  
**Total Files**: 23  
**Lines of Code**: ~3000+ (SQL, YAML, Markdown)
