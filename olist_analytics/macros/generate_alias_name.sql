# Macros for Olist dbt project

{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if custom_alias_name is none -%}
        {{ node.name }}
    {%- else -%}
        {{ custom_alias_name | trim }}
    {%- endif -%}
{%- endmacro %}


{% macro calculate_revenue(price_col, freight_col='freight_value') -%}
  ROUND({{ price_col }} + COALESCE({{ freight_col }}, 0), 2)
{%- endmacro %}


{% macro grant_permissions(model_name, schema_name) -%}
  -- Macro to grant select permissions on a model
  -- Usage: call grant_permissions('fct_sales', 'marts')
  {% set sql %}
    GRANT `roles/bigquery.dataViewer` ON SCHEMA `{{ schema_name }}`
    TO "serviceAccount:analytics@project.iam.gserviceaccount.com"
  {% endset %}
  
  {% do log("Granting permissions on " ~ schema_name, info=true) %}
  {# Uncomment to execute:
  {% do run_query(sql) %}
  #}
{%- endmacro %}
