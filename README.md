# obp-audit-log

### 1. Set Up Logical Replication in PostgreSQL

Enable logical replication on your PostgreSQL database to capture changes.

- **Set access keys**
``` bash
aws configure set aws_access_key_id testUser
aws configure set aws_secret_access_key testAccessKey
aws configure set region us-east-2
```

- **Configure PostgreSQL for Logical Replication:**
  ```sql
    ALTER SYSTEM SET wal_level = logical;
    ALTER SYSTEM SET max_replication_slots = 4;
    ALTER SYSTEM SET max_wal_senders = 4;

    CREATE TABLE customers (
        id SERIAL PRIMARY KEY,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        phone_number VARCHAR(20),
        address TEXT,
        city VARCHAR(50),
        state VARCHAR(50),
        zip_code VARCHAR(10),
        country VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    ALTER TABLE public.customers REPLICA IDENTITY FULL;
  ```

- **Create a Replication Slot:**
  ```sql
    SELECT * FROM pg_create_logical_replication_slot('my_slot', 'pgoutput');
  ```

- **Create a Publication:**
  ```sql
    CREATE PUBLICATION my_publication FOR ALL TABLES;
  ```

### 2. Use Debezium for Change Data Capture (CDC)

Debezium is an open-source tool that can stream changes from the replication slot to a Kafka topic.

- **Set Up Debezium Connector:**
  Configure Debezium to connect to your PostgreSQL database and capture changes.
  ```bash
    sh deploy-source.sh
  ```

- **Set Up S3 Sink Connector:**
  Configure Kafka to connect to S3.
  ```bash
    sh deploy-sink.sh
  ```

### 3. Stream Data to Apache Kafka

Use Kafka to transport the changes captured by Debezium.

- **Run Kafka and Kafka Connect:**
  Ensure Kafka and Kafka Connect are running, and the Debezium connector is configured to stream changes to Kafka topics.

### 4. Process and Write Data to Parquet with Apache Spark

Use Apache Spark to process Kafka streams and write data to Parquet files.

- **Spark Structured Streaming:**
  ```python
  from pyspark.sql import SparkSession
  from pyspark.sql.functions import from_json, col
  from pyspark.sql.types import StructType, StructField, StringType, IntegerType

  spark = SparkSession.builder \
      .appName("KafkaToParquet") \
      .getOrCreate()

  schema = StructType([
      StructField("op", StringType()),
      StructField("before", StructType([
          StructField("id", IntegerType()),
          StructField("name", StringType())
      ])),
      StructField("after", StructType([
          StructField("id", IntegerType()),
          StructField("name", StringType())
      ]))
  ])

  kafka_df = spark.readStream \
      .format("kafka") \
      .option("kafka.bootstrap.servers", "localhost:9092") \
      .option("subscribe", "dbserver1.public.customers") \
      .load()

  json_df = kafka_df.select(from_json(col("value").cast("string"), schema).alias("data"))
  parquet_df = json_df.select("data.after.*")

  query = parquet_df.writeStream \
      .outputMode("append") \
      .format("parquet") \
      .option("path", "/path/to/parquet/files") \
      .option("checkpointLocation", "/path/to/checkpoint/dir") \
      .start()

  query.awaitTermination()
  ```

### 5. Query Parquet Files with Apache Hudi or Spark SQL

- **Use Apache Hudi:**
  Apache Hudi provides capabilities for managing Parquet files and incremental data processing.
  ```python
  # Read the Hudi dataset
  hudi_df = spark.read.format("hudi").load("/path/to/parquet/files")
  hudi_df.createOrReplaceTempView("hudi_table")
  spark.sql("SELECT * FROM hudi_table WHERE ...").show()
  ```

- **Use Spark SQL:**
  ```python
  parquet_df = spark.read.parquet("/path/to/parquet/files")
  parquet_df.createOrReplaceTempView("parquet_table")
  spark.sql("SELECT * FROM parquet_table WHERE ...").show()
  ```

### Summary

1. **Enable logical replication** in PostgreSQL.
2. **Use Debezium** to capture changes and stream them to Kafka.
3. **Use Spark Structured Streaming** to process Kafka streams and write them to Parquet files.
4. **Use Apache Hudi or Spark SQL** to query the Parquet files.
