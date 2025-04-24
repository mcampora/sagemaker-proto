#!/bin/zsh

# This script creates a DataZone domain for SageMaker Unified Studio.
#----------------------------------------------------------------------------------------------------------------

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

# Retrieve the arn of the roles
#----------------------------------------------------------------------------------------------------------------
export SAGEMAKER_DOMAIN_EXECUTION=$( aws iam get-role --role-name ${SAGEMAKER_DOMAIN_EXECUTION_NAME} | jq -r '.Role.Arn' )
export SAGEMAKER_DOMAIN_SERVICE=$( aws iam get-role --role-name ${SAGEMAKER_DOMAIN_SERVICE_NAME} | jq -r '.Role.Arn' )

# Create the domain, save its name and arn for later use
#----------------------------------------------------------------------------------------------------------------
echo "Create domain ${DOMAIN}!"

RES=$( aws datazone create-domain \
  --description "Test domain for SageMaker Unified Studio" \
  --domain-execution-role ${SAGEMAKER_DOMAIN_EXECUTION} \
  --domain-version V2 \
  --name ${DOMAIN} \
  --service-role ${SAGEMAKER_DOMAIN_SERVICE} \
  --single-sign-on type="IAM_IDC",userAssignment="AUTOMATIC" \
  --region ${AWS_REGION})

echo ${DOMAIN} > ./data/domain.name
echo ${RES} | jq -r '.arn' > ./data/domain.arn
DOMAIN_ID=$( echo ${RES} | jq -r '.id' )
echo ${DOMAIN_ID} > ./data/domain.id
