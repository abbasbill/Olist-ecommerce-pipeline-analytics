# Custom dbt tests for Olist analytics project

{% test revenue_positive(model, column_name) %}
  -- Test to ensure revenue is always positive (or zero)
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} < 0
{% endtest %}

{% test no_future_orders(model, column_name) %}
  -- Test to ensure order dates are not in the future
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} > CURRENT_TIMESTAMP()
{% endtest %}
