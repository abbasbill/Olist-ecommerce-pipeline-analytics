{{ config(materialized='view', tags=['staging', 'payments']) }}

SELECT
    order_id,
    payment_type,
    SUM(payment_value) AS total_payment_value,
    SUM(payment_installments) AS total_installments,
    MAX(payment_sequential) AS payment_count
FROM {{ source('raw', 'olist_order_payments_dataset') }}
WHERE payment_value IS NOT NULL
GROUP BY order_id, payment_type
