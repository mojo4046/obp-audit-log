# Post the configuration for the Debezium PostgreSQL connector to Kafka Connect
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '
{
  "name": "s3-sink",
  "config": {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "tasks.max": "1",
    "topics": "postgres-json.public.customers",
    "s3.region": "us-east-2",
    "store.url": "http://localstack:4566",
    "s3.bucket.name": "sync-bucket",
    "s3.part.size": "5242880",
    "flush.size": "3",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "keys.format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "schema.compatibility": "NONE",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter", 
    "key.converter.schemas.enable": "false",
    "value.converter.schemas.enable": "false",
    "name": "s3-sink",
    "aws.access.key.id": "testUser",
    "aws.secret.access.key": "testAccessKey",
    "store.kafka.keys": "true"
  }
}'