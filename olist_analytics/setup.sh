#!/bin/bash
# Script to setup dbt project locally

echo "Installing dbt and dependencies..."
pip install -r requirements.txt

echo "Installing dbt packages..."
dbt deps

echo "Testing connection..."
dbt debug

echo "Setup complete! Next steps:"
echo "1. Update olist_analytics/profiles.yml with your GCP project ID"
echo "2. Run 'dbt run' to execute models"
echo "3. Run 'dbt test' to run tests"
echo "4. Run 'dbt docs generate && dbt docs serve' to view documentation"
