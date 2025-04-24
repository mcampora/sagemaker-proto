#!/bin/zsh

# The scripts make several assumptions:
#   - AWS CLI and jq are installed and configured
#   - AWS credentials for the domain and producer account are set with in the environment (with the correct permissions)
#   - 2 roles are already created: AmazonSageMakerDomainExecution and AmazonSageMakerDomainService
#   - an SSO identity center is defined in the targeted region

# domain and producer account credentials
export PRODUCER_AWS_ACCESS_KEY_ID=""
export PRODUCER_AWS_SECRET_ACCESS_KEY=""
export PRODUCER_AWS_SESSION_TOKEN=""

# consumer account credentials
export CONSUMER_AWS_ACCESS_KEY_ID=""
export CONSUMER_AWS_SECRET_ACCESS_KEY=""
export CONSUMER_AWS_SESSION_TOKEN=""

# by default select the producer credentials
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

# targeted region
export AWS_REGION=eu-west-1

# account id of the domain and producer account
export PRODUCER_ACCOUNT_ID=718361999865

# account id of the consumer account
export CONSUMER_ACCOUNT_ID=608495930665

# Glue table
export S3_PREFIX=test-sagemaker
export DATABASE=testsagemaker
export TABLE=inventory

# roles used by the domain to provision resources
export SAGEMAKER_DOMAIN_EXECUTION_NAME=AmazonSageMakerDomainExecution
export SAGEMAKER_DOMAIN_SERVICE_NAME=AmazonSageMakerDomainService

# domain name
export DOMAIN=test-sagemaker

# have to harden this part:
# - domain
#   - create the roles instead of assuming they exist
# - producer
#   - publish the table in the catalog
# - write a serious cleanup
# - then move to the consumer part
#   - create the consumer project profile
#   - create the consumer project
#   - subscribe to the table
#   - accept the subscription