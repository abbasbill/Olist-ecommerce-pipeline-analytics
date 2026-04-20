# ecommerce-olist-analytics-pipeline
End-to-End Batch Data Engineering Pipeline on GCP – Overview, Architecture Plan &amp; Data Flow

## Prerequisites

1. 


2. BigQuery credentials
    - Project ID
    - Private key
    - Client email
    
    >Learn more about obtaining BigQuery credentials in `dlt`'s [documentation](https://dlthub.com/docs/dlt-ecosystem/destinations/bigquery).

## Setup Guide

1. **Create a Virtual Environment**: It's advised to create a virtual environment to maintain a clean workspace and prevent dependency conflicts, although this is not mandatory.

2. **Create an .env File**: Within your repository, create an ``.env`` file, copy and paste your secret keys
 To securely store credentials in base64 format. Prefix each secret with 'SECRET_' by executing the `encode-secret.sh bash script` in order for Kestra's [`secret()`](https://kestra.io/docs/developer-guide/variables/function/secret) function to work. The file should look like this: 

    ```env
    SECRET_BIGQUERY_PROJECT_ID=someSecretValueInBase64
    SECRET_BIGQUERY_PRIVATE_KEY=someSecretValueInBase64
    SECRET_BIGQUERY_CLIENT_EMAIL=someSecretValueInBase64

    ```

   >The base64 format is required because Kestra mandates it.
  
    Find out more about managing secrets in Kestra [here](https://kestra.io/docs/developer-guide/secrets).

3. **Download Docker Desktop**: As recommended by Kestra, download and install Docker Desktop.

4. **Download Docker Compose File**: Verify that Docker is active and download the Docker Compose file using the following command:
   ```bash
    curl -o docker-compose.yml \
    https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
    ```
    *
5. **Configure Docker Compose File**: Modify your Docker Compose file to include the ``.env`` file:

    ```yaml
    kestra:
        image: kestra/kestra:develop-full
        env_file:
            - .env
    ``` 

6. **Enable Auto-Restart in Docker Compose**: Add ``restart: always`` to the `postgres` and `kestra` services in your `docker-compose.yml`. This ensures they automatically restart after a system reboot:

    ```yaml
    postgres:
        image: postgres
        restart: always
    ```

    ```yaml
    kestra:
        image: kestra/kestra:latest-full
        restart: always
    ```
7. **Start Kestra Server**: Run the following command:
   ```bash
    docker compose up -d
    ```
8. **Access Kestra UI**: Launch http://localhost:8080/ to open the Kestra UI.


## REFERENCES
- [Configure Secrets in Kestra](https://kestra.io/docs/how-to-guides/secrets)
- [Secrets in Kestra – Store Sensitive Values Securely](https://kestra.io/docs/concepts/secret)