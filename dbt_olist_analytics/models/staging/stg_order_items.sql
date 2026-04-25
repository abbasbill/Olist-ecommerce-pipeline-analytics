{{ config(materialized='view', tags=['staging', 'order_items']) }}

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    CAST(price AS FLOAT64) AS price,
    CAST(freight_value AS FLOAT64) AS freight_value,
    shipping_limit_date
FROM {{ source('raw', 'olist_order_items_dataset') }}
WHERE price IS NOT NULL
  AND order_id IS NOT NULL
