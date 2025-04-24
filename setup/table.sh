#!/bin/zsh

# This script creates a Glue table for the tests
#----------------------------------------------------------------------------------------------------------------

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

# create a bucket
S3_BUCKET=${S3_PREFIX}-${PRODUCER_ACCOUNT_ID}
echo ${S3_BUCKET} > ./data/bucket.name
aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}

# create a Glue database using Athena
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS ${DATABASE} LOCATION 's3://${S3_BUCKET}/${DATABASE}/';" \
  --result-configuration OutputLocation="s3://${S3_BUCKET}/athena/" \
  --region ${AWS_REGION}

# create a Glue table using Athena
aws athena start-query-execution \
  --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS ${DATABASE}.${TABLE} (id INT, name STRING, quantity INT) LOCATION 's3://${S3_BUCKET}/${DATABASE}/${TABLE}/';" \
  --result-configuration OutputLocation="s3://${S3_BUCKET}/athena/" \
  --region ${AWS_REGION}

# fill the Glue table with a couple of records
aws athena start-query-execution \
  --query-string "INSERT INTO ${DATABASE}.${TABLE} VALUES (1, 'pen', 10), (2, 'pencil', 20), (3, 'brush', 30);" \
  --result-configuration OutputLocation="s3://${S3_BUCKET}/athena/" \
  --region ${AWS_REGION}

# register the location in LakeFormation
S3_BUCKET_ARN=arn:aws:s3:::${S3_BUCKET}/${DATABASE}/${TABLE}
echo ${S3_BUCKET_ARN} > ./data/bucket.arn
aws lakeformation register-resource \
  --resource-arn ${S3_BUCKET_ARN} \
  --use-service-linked-role \
  --no-hybrid-access-enabled \
  --region ${AWS_REGION}
