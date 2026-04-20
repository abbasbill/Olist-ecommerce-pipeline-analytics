#!/bin/bash

# encoding script for environment variables and credentials
# Encodes .env variables with SECRET_ prefix and base64-encodes the GCP credentials JSON

set -e  # Exit on error

ENV_FILE=".env"
CREDENTIALS_FILE="keys/gcp-credentials.json" #create key/gcp-credentials.json file with your GCP credentials and add to .gitignore
ENV_ENCODED=".env_encoded"
CREDS_ENCODED=".credentials_encoded"

echo "Starting encoding process..."

# Check if files exist
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    echo "Error: $CREDENTIALS_FILE not found"
    exit 1
fi

# Step 1: Encode .env file with SECRET_ prefix
echo "Encoding $ENV_FILE → $ENV_ENCODED"
while IFS='=' read -r key value; do
    echo "SECRET_$key=$(echo -n "$value" | base64)";
done < "$ENV_FILE" > "$ENV_ENCODED"
echo "Encoded .env variables ($(wc -l < "$ENV_ENCODED") entries)"

# Step 2: Encode credentials JSON
echo "Encoding $CREDENTIALS_FILE → $CREDS_ENCODED"
base64 -w 0 "$CREDENTIALS_FILE" > "$CREDS_ENCODED"
echo "Encoded GCP credentials"

# Step 3: Append credentials to .env_encoded
echo "Appending GCP credentials → $ENV_ENCODED"
{
    echo ""
    echo "# Encoded GCP credentials (base64)"
    echo "SECRET_GOOGLE_APPLICATION_CREDENTIALS=$(cat "$CREDS_ENCODED")"
} >> "$ENV_ENCODED"
echo "Appended GCP credentials to $ENV_ENCODED"

echo ""
echo "Encoding complete!"
echo ""
echo "Generated files:"
echo "   - $ENV_ENCODED (SECRET_ prefixed env vars + GCP credentials)"
echo "   - $CREDS_ENCODED (base64 GCP credentials)"
echo ""