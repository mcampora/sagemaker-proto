#!/bin/zsh

# This script imports an existing Glue table in the producer project
#----------------------------------------------------------------------------------------------------------------

DOMAIN_ID=$( cat ./data/domain.id )
PROJECT_ID=$( cat ./data/producer_project.id )

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

# get the id of the lakehouse environment
aws datazone list-environments --domain-identifier ${DOMAIN_ID} --region ${AWS_REGION} --project-identifier ${PROJECT_ID} | jq -r '.items[] | select(.name=="Lakehouse Database") | .id' > ./data/producer_environment.id
ENVIRONMENT_ID=$( cat ./data/producer_environment.id )

# get the role associated with the project/environment
aws datazone get-environment --domain-identifier ${DOMAIN_ID} --identifier ${ENVIRONMENT_ID} | jq -r '.provisionedResources[] | select(.name=="userRoleArn") | .value' > ./data/producer_role.arn
PRODUCER_ROLE_ARN=$( cat ./data/producer_role.arn )

# grant permissions to the test database
echo "Grant access to the test table to the producer project! "
aws lakeformation grant-permissions \
  --principal="DataLakePrincipalIdentifier=${PRODUCER_ROLE_ARN}" \
  --permissions "ALL" \
  --permissions-with-grant-option "ALL" \
  --resource="{\"Database\":{\"Name\":\"${DATABASE}\"}}" \
  --region ${AWS_REGION} \
  --no-cli-pager

# grant permissions to the test table
aws lakeformation grant-permissions \
  --principal="DataLakePrincipalIdentifier=${PRODUCER_ROLE_ARN}" \
  --permissions "ALL" "DESCRIBE" "SELECT" \
  --permissions-with-grant-option "DESCRIBE" "SELECT" \
  --resource="{\"Table\":{\"DatabaseName\":\"${DATABASE}\", \"Name\":\"${TABLE}\"}}" \
  --region ${AWS_REGION} \
  --no-cli-pager

