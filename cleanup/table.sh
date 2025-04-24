#!/bin/zsh

# This script deletes the Glue table and s3 bucket created for the tests
#----------------------------------------------------------------------------------------------------------------

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

S3_BUCKET=$( cat ./data/bucket.name )

# delete the Glue table
aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS ${DATABASE}.${TABLE};" \
  --result-configuration OutputLocation="s3://${S3_BUCKET}/athena/" \
  --region ${AWS_REGION}

# delete the Glue database
aws athena start-query-execution \
  --query-string "DROP DATABASE IF EXISTS ${DATABASE};" \
  --result-configuration OutputLocation="s3://${S3_BUCKET}/athena/" \
  --region ${AWS_REGION}

# unregister the location in LakeFormation
S3_BUCKET_ARN=$( cat ./data/bucket.arn )
aws lakeformation deregister-resource \
  --resource-arn ${S3_BUCKET_ARN} \
  --region ${AWS_REGION}

# empty the bucket
aws s3 rm s3://${S3_BUCKET}/athena --recursive
aws s3 rm s3://${S3_BUCKET}/${DATABASE} --recursive

# delete the bucket
aws s3api delete-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION}
