# Looker Studio Dashboard Guide - Olist Sales Analytics

This guide walks through creating the two recommended dashboard tiles for Olist sales performance analytics using Looker Studio.

## Dashboard Overview

**Purpose**: Track sales performance with key metrics: category distribution and temporal trends  
**Data Source**: BigQuery `marts.fct_sales` table  
**Update Frequency**: Daily (after dbt pipeline completes)

## Prerequisites

- Access to BigQuery project with `marts.fct_sales` table
- Looker Studio account
- Service account credentials for BigQuery connection

## Setup Steps

### 1. Connect BigQuery to Looker Studio

1. Go to [Looker Studio](https://datastudio.google.com)
2. Click **+ Create** → **Report**
3. Click **Create new data source**
4. Select **BigQuery** connector
5. Authorize Google account
6. Select your GCP project
7. Select dataset: `marts`
8. Select table: `fct_sales`
9. Click **Create**

### 2. Tile 1: Revenue Distribution by Product Category

**Visualization**: Horizontal Bar Chart  
**Purpose**: Show which product categories generate the most revenue

#### Setup Steps

1. Add new chart to your report
2. Chart type: **Horizontal Bar**
3. Dimension: `product_category_name_english`
4. Metric: `SUM(revenue)`
5. Sort: Descending by revenue
6. Settings:
   - **Max rows**: 15 (show top 15 categories + Others bucket)
   - **Colors**: Use default palette
   - **Data range**: Add date range filter for flexibility

#### Styling

- **Title**: "Revenue Distribution by Product Category (English)"
- **Subtitle**: "Top 15 categories in BRL"
- **Number format**: Currency (BRL - Brazilian Real)
- **Show legend**: Yes

#### Advanced (Optional)

- Add a **Scorecard** above showing total revenue across all categories
- Add a **Date range control** to allow users to filter by order_month
- Enable **Data refresh** to update hourly

#### SQL Equivalent

```sql
SELECT 
  product_category_name_english,
  SUM(revenue) as total_revenue,
  COUNT(*) as order_count
FROM marts.fct_sales
WHERE order_purchase_timestamp >= DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY product_category_name_english
ORDER BY total_revenue DESC
LIMIT 15
```

---

### 3. Tile 2: Monthly Revenue Trend

**Visualization**: Line Chart  
**Purpose**: Show sales trends over time (seasonality, growth, decline)

#### Setup Steps

1. Add new chart to your report
2. Chart type: **Line Chart**
3. Dimension: `order_month` (date)
4. Metric: `SUM(revenue)`
5. Sort: Ascending by date
6. Settings:
   - **Smooth curve**: Yes (for smoother visualization)
   - **Show values**: Yes (display data points)
   - **Show comparison**: Optional (previous period)

#### Styling

- **Title**: "Monthly Revenue Trend"
- **Subtitle**: "Sales performance from 2016-2018"
- **Number format**: Currency (BRL)
- **Y-axis label**: "Revenue (BRL)"
- **X-axis label**: "Month"

#### Advanced (Optional)

- Enable **trend line** (Analytics > Trend Line) to see overall direction
- Add a **Data range control** for custom date filtering
- Color by `order_status` to see if delivered vs shipped differs
- Add **Y-axis min/max bounds** for consistent scaling

#### SQL Equivalent

```sql
SELECT 
  DATE_TRUNC(order_purchase_timestamp, MONTH) as month,
  SUM(revenue) as monthly_revenue,
  COUNT(DISTINCT order_id) as order_count
FROM marts.fct_sales
GROUP BY DATE_TRUNC(order_purchase_timestamp, MONTH)
ORDER BY month ASC
```

---

## Dashboard Layout Recommendations

### Option 1: Side by Side (Recommended)

```
┌─────────────────────────────────────────────────┐
│  Olist Sales Performance Dashboard              │
├──────────────────────────┬──────────────────────┤
│                          │                      │
│  Revenue by Category     │  Monthly Trend       │
│  (Horizontal Bar)        │  (Line Chart)        │
│                          │                      │
│  Top 15 categories       │  2016-2018 timeline  │
│  showing revenue mix     │  showing seasonality │
│                          │                      │
└──────────────────────────┴──────────────────────┘
```

### Option 2: Stacked (Alternative)

```
┌────────────────────────────────────────────────┐
│  Olist Sales Performance Dashboard             │
├────────────────────────────────────────────────┤
│  Total Revenue: 1,245,678 BRL  | Orders: 98.5K│
├────────────────────────────────────────────────┤
│             Monthly Revenue Trend               │
│            (Line Chart - 60% height)           │
├────────────────────────────────────────────────┤
│         Revenue Distribution by Category       │
│        (Horizontal Bar - 40% height)           │
└────────────────────────────────────────────────┘
```

---

## Filters to Add (Optional but Recommended)

1. **Date Range Control**: Filter by `order_month`
   - Users can select custom date ranges
   - Default: Last 12 months

2. **Payment Type Filter**: Filter by `payment_type`
   - Show revenue by payment method
   - Help identify payment trends

3. **Order Status Filter**: Filter by `order_status`
   - Shipped vs Delivered
   - Exclude cancelled/processing

### Add Filters

1. Click **Filter** (top menu)
2. Click **Create New Filter**
3. Select field: `order_purchase_timestamp` (for date range)
4. Filter type: **Date range**
5. Apply to all charts

---

## Dashboard Sharing & Collaboration

### Share Report

1. Click **Share** (top right)
2. Choose:
   - **Shared with me**: Invite specific users
   - **Public link**: Share with anyone
   - **Embedded**: Add to website/dashboard

### Schedule Refresh

1. Click **File** → **Report settings**
2. Enable **Automatic refresh**
3. Set frequency: Hourly or every 6 hours
4. This ensures data stays current with dbt pipeline

---

## Common Issues & Troubleshooting

### Issue: "No data" in charts

**Solution**: 
- Verify `marts.fct_sales` table exists in BigQuery
- Check dbt job completed successfully
- Ensure service account has BigQuery read permissions
- Check date filters aren't too restrictive

### Issue: Slow dashboard loading

**Solution**:
- Reduce max rows in bar chart (10 instead of 15)
- Enable materialized table in dbt config (already done)
- Check BigQuery cluster_by is optimized (already set)
- Reduce date range in filters

### Issue: Wrong currency showing

**Solution**:
- Double-check metric formatting is set to BRL
- Verify source data values are in BRL (they should be)

---

## Next Steps

1. **Save report**: File → Save (give it a name like "Olist Sales Dashboard")
2. **Add to favorites**: Star icon to quick access
3. **Set data refresh**: Report settings → Auto-refresh hourly
4. **Share with team**: Share button to invite collaborators
5. **Monitor KPIs**: Check revenue trends weekly

---

## KPIs to Monitor

From these two tiles, track:

- **Top 3 Revenue Categories**: Which product types drive most sales?
- **Month-over-Month Growth**: Are sales increasing?
- **Seasonal Patterns**: When do peak sales occur?
- **Category Concentration**: Are sales well-distributed or concentrated?
- **YoY Comparison**: Use comparison feature to check year-over-year trends

---

## Advanced: Custom Metrics (Optional)

If you want to add more sophistication later:

```sql
-- Average order value by category
SELECT 
  product_category_name_english,
  ROUND(AVG(revenue), 2) as avg_order_value,
  COUNT(*) as order_count
FROM marts.fct_sales
GROUP BY product_category_name_english
```

Then create a **Scorecard** for "Average Order Value" by category.

---

## Resources

- [Looker Studio Best Practices](https://support.google.com/looker-studio)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [dbt Documentation](https://docs.getdbt.com)

---

**Last Updated**: April 2026  
**Dashboard Template Version**: 1.0
