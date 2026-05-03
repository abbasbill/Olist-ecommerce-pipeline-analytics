{{ config(materialized='view', tags=['staging', 'orders']) }}

SELECT
    order_id,
    customer_id,
    REPLACE(order_status, 'canceled', 'cancelled')  AS order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM {{ source('raw', 'orders') }}
WHERE order_purchase_timestamp IS NOT NULL