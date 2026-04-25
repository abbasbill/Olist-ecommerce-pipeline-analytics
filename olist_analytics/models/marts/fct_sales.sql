{{ config(
    materialized='table',
    tags=['marts', 'sales', 'production'],
    partition_by={
        'field': 'order_month',
        'data_type': 'date'
    },
    cluster_by=['product_category_name_english', 'payment_type']
) }}

SELECT
    oi.order_id,
    oi.order_item_id,
    o.order_purchase_timestamp,
    DATE_TRUNC(o.order_purchase_timestamp, MONTH) AS order_month,
    o.customer_id,
    o.order_status,
    p.product_id,
    p.product_category_name,
    p.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + COALESCE(oi.freight_value, 0), 2) AS revenue,
    pay.payment_type,
    pay.total_payment_value,
    oi.seller_id,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM {{ ref('stg_order_items') }} oi
INNER JOIN {{ ref('stg_orders') }} o
    ON oi.order_id = o.order_id
LEFT JOIN {{ ref('stg_products') }} p
    ON oi.product_id = p.product_id
LEFT JOIN {{ ref('stg_payments') }} pay
    ON oi.order_id = pay.order_id
WHERE o.order_status IN ('delivered', 'shipped')
  AND oi.price > 0
  AND o.order_purchase_timestamp >= TIMESTAMP('{{ var("start_date") }}')
  AND o.order_purchase_timestamp <= TIMESTAMP('{{ var("end_date") }}')
