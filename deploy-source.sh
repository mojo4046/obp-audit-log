#!/bin/bash

# Update and install postgresql-13-wal2json in the Docker container named 'postgres'
# echo Y | docker exec -i postgres bash -c "apt-get update && apt-get install postgresql-13-wal2json"

# Post the configuration for the Debezium PostgreSQL connector to Kafka Connect
# https://debezium.io/documentation/reference/2.6/connectors/postgresql.html
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
    "name": "postgres_source",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "tasks.max": "3",
        "database.user": "postgres",
        "database.dbname": "postgres",
        "database.server.name": "postgres-json",
        "database.port": "5432",
        "plugin.name": "pgoutput",
        "slot.name": "my_slot",
        "plugin.name": "pgoutput",
        "publication.name": "my_publication",
        "table.whitelist": "public.customers",
        "key.converter.schemas.enable": "false",
        "database.hostname": "postgres",
        "database.password": "postgres",
        "value.converter.schemas.enable": "false",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "snapshot.mode": "always",
        "transforms": "ExtractStringKey",
        "transforms.ExtractStringKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
        "transforms.ExtractStringKey.field": "id",
        "transforms.ExtractStringKey.key.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
}'