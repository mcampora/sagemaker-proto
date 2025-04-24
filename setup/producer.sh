#!/bin/zsh

# This script configure the producer artefacts (blueprints, project profile, project, asset)
#----------------------------------------------------------------------------------------------------------------

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

DOMAIN_ID=$( cat ./data/domain.id )

# create the roles if required
#----------------------------------------------------------------------------------------------------------------
ACCESS_ROLE_NAME=AmazonSageMakerManageAccess-${AWS_REGION}-${DOMAIN_ID}
PROVISIONING_ROLE_NAME=AmazonSageMakerProvisioning-${PRODUCER_ACCOUNT_ID}

# check if the access role already exists
ACCESS_ROLE=$( aws iam get-role --role-name ${ACCESS_ROLE_NAME} 2>/dev/null )
if [ -z ${ACCESS_ROLE} ]; then
    echo "Create the access role ${ACCESS_ROLE_NAME}! "

    # create the trust policy
    echo "{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"Service\": \"datazone.amazonaws.com\" }, \"Action\": \"sts:AssumeRole\", \"Condition\": { \"StringEquals\": { \"aws:SourceAccount\": \"${PRODUCER_ACCOUNT_ID}\" }, \"ArnEquals\": { \"aws:SourceArn\": \"arn:aws:datazone:${AWS_REGION}:${PRODUCER_ACCOUNT_ID}:domain/${DOMAIN_ID}\"}}}]}" > ./data/producer_access_role.json

    # create the access role
    aws iam create-role \
        --role-name ${ACCESS_ROLE_NAME} \
        --assume-role-policy-document file://./data/producer_access_role.json \
        --region ${AWS_REGION} \
        --no-cli-pager

    # attach the policies to the roles
    aws iam attach-role-policy \
        --role-name ${ACCESS_ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonDataZoneGlueManageAccessRolePolicy \
        --region ${AWS_REGION}
    aws iam attach-role-policy \
        --role-name ${ACCESS_ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/AmazonDataZoneSageMakerManageAccessRolePolicy \
        --region ${AWS_REGION}

    ACCESS_ROLE=$( aws iam get-role --role-name ${ACCESS_ROLE_NAME} 2>/dev/null )
else
  echo "The access role ${ACCESS_ROLE_NAME} already exists! "
fi
ACCESS_ROLE_ARN=$( echo ${ACCESS_ROLE} | jq -r '.Role.Arn' )

# check if the provisioning role already exists
PROVISIONING_ROLE=$( aws iam get-role --role-name ${PROVISIONING_ROLE_NAME} 2>/dev/null )
if [ -z ${PROVISIONING_ROLE} ]; then
    echo "Create the provisioning role ${PROVISIONING_ROLE_NAME}! "
  
    # create the trust policy
    echo "{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"Service\": \"datazone.amazonaws.com\" }, \"Action\": \"sts:AssumeRole\", \"Condition\": { \"StringEquals\": { \"aws:SourceAccount\": \"${PRODUCER_ACCOUNT_ID}\" }}}]}" > ./data/producer_provisioning_role.json

    # create the provisioning role
    aws iam create-role \
        --role-name ${PROVISIONING_ROLE_NAME} \
        --assume-role-policy-document file://./data/producer_provisioning_role.json \
        --region ${AWS_REGION} \
        --no-cli-pager

    # attach the policies to the roles
    aws iam attach-role-policy \
        --role-name ${PROVISIONING_ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/service-role/SageMakerStudioProjectProvisioningRolePolicy \
        --region ${AWS_REGION}

    PROVISIONING_ROLE=$( aws iam get-role --role-name ${PROVISIONING_ROLE_NAME} 2>/dev/null )
else
  echo "The provisioning role ${PROVISIONING_ROLE_NAME} already exists! "
fi
PROVISIONING_ROLE_ARN=$( echo ${PROVISIONING_ROLE} | jq -r '.Role.Arn' )

# configure the blueprints
#----------------------------------------------------------------------------------------------------------------
# find the blueprint ids
TOOLING_ID=$( aws datazone list-environment-blueprints --domain-identifier ${DOMAIN_ID} --region ${AWS_REGION} --managed --name Tooling | jq -r '.items[].id' )
DATALAKE_ID=$( aws datazone list-environment-blueprints --domain-identifier ${DOMAIN_ID} --region ${AWS_REGION} --managed --name DataLake | jq -r '.items[].id' )
REDSHIFT_SERVERLESS_ID=$( aws datazone list-environment-blueprints --domain-identifier ${DOMAIN_ID} --region ${AWS_REGION} --managed --name RedshiftServerless | jq -r '.items[].id' )

# find the root domain unit id
ROOT_DOMAIN_UNIT_ID=$( aws datazone get-domain --region eu-west-1 --identifier ${DOMAIN_ID} | jq -r '.rootDomainUnitId' )
echo ${ROOT_DOMAIN_UNIT_ID} > ./data/root_domain_unit.id

# configure the Datalake blueprint
echo "Configure the datalake blueprint!"
aws datazone put-environment-blueprint-configuration \
  --domain-identifier ${DOMAIN_ID} \
  --enabled-regions ${AWS_REGION} \
  --environment-blueprint-identifier ${DATALAKE_ID} \
  --manage-access-role-arn ${ACCESS_ROLE_ARN} \
  --provisioning-role-arn ${PROVISIONING_ROLE_ARN} \
  --no-cli-pager \
  --region ${AWS_REGION}

aws datazone add-policy-grant \
    --detail="{\"createEnvironmentFromBlueprint\":{}}" \
    --domain-identifier ${DOMAIN_ID} \
    --entity-type ENVIRONMENT_BLUEPRINT_CONFIGURATION \
    --entity-identifier ${PRODUCER_ACCOUNT_ID}:${DATALAKE_ID} \
    --policy-type CREATE_ENVIRONMENT_FROM_BLUEPRINT \
    --no-cli-pager \
    --principal="{\"project\":{\"projectDesignation\":\"CONTRIBUTOR\",\"projectGrantFilter\":{\"domainUnitFilter\":{\"domainUnit\":\"${ROOT_DOMAIN_UNIT_ID}\",\"includeChildDomainUnits\":true}}}}"
 
# configure the Redshift blueprint
echo "Configure the redshift blueprint!"
aws datazone put-environment-blueprint-configuration \
  --domain-identifier ${DOMAIN_ID} \
  --enabled-regions ${AWS_REGION} \
  --environment-blueprint-identifier ${REDSHIFT_SERVERLESS_ID} \
  --manage-access-role-arn ${ACCESS_ROLE_ARN} \
  --provisioning-role-arn ${PROVISIONING_ROLE_ARN} \
  --no-cli-pager \
  --region ${AWS_REGION}

aws datazone add-policy-grant \
    --detail="{\"createEnvironmentFromBlueprint\":{}}" \
    --domain-identifier ${DOMAIN_ID} \
    --entity-type ENVIRONMENT_BLUEPRINT_CONFIGURATION \
    --entity-identifier ${PRODUCER_ACCOUNT_ID}:${REDSHIFT_SERVERLESS_ID} \
    --policy-type CREATE_ENVIRONMENT_FROM_BLUEPRINT \
    --no-cli-pager \
    --principal="{\"project\":{\"projectDesignation\":\"CONTRIBUTOR\",\"projectGrantFilter\":{\"domainUnitFilter\":{\"domainUnit\":\"${ROOT_DOMAIN_UNIT_ID}\",\"includeChildDomainUnits\":true}}}}"
 
# configure the Tooling blueprint
echo "Configure the tooling blueprint!"

# need an S3 bucket
DOMAIN_S3_BUCKET_PREFIX=amazon-sagemaker-${PRODUCER_ACCOUNT_ID}-${AWS_REGION}
DOMAIN_S3_BUCKET=$( aws s3api list-buckets --prefix amazon-sagemaker-${PRODUCER_ACCOUNT_ID}-${AWS_REGION} | jq -r '.Buckets[0].Name' )
if [[ ${DOMAIN_S3_BUCKET} == "null" ]]; then
    DOMAIN_S3_BUCKET=${DOMAIN_S3_BUCKET_PREFIX}
    echo "Create the domain bucket ${DOMAIN_S3_BUCKET}!"
    # create the bucket
    aws s3api create-bucket --bucket ${DOMAIN_S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}
else
  echo "The domain bucket ${DOMAIN_S3_BUCKET} already exists! "
fi
echo ${DOMAIN_S3_BUCKET} > ./data/domain_bucket.name

# need a VPC and 3 subnets / AZ (pick the defaults)
VPC_ID=$( aws ec2 describe-vpcs --region ${AWS_REGION} --filters Name=is-default,Values=true | jq -r '.Vpcs[0].VpcId' )
SUBNETS=$( aws ec2 describe-subnets --region ${AWS_REGION} --filters Name=vpc-id,Values="${VPC_ID}" )
ID1=$( echo ${SUBNETS} | jq -r '.Subnets[0].SubnetId' )
ID2=$( echo ${SUBNETS} | jq -r '.Subnets[1].SubnetId' )
ID3=$( echo ${SUBNETS} | jq -r '.Subnets[2].SubnetId' )
AZ1=$( echo ${SUBNETS} | jq -r '.Subnets[0].AvailabilityZoneId' )
AZ2=$( echo ${SUBNETS} | jq -r '.Subnets[1].AvailabilityZoneId' )
AZ3=$( echo ${SUBNETS} | jq -r '.Subnets[2].AvailabilityZoneId' )
IDS="${ID1},${ID2},${ID3}"
AZS="${AZ1},${AZ2},${AZ3}"

aws datazone put-environment-blueprint-configuration \
  --domain-identifier ${DOMAIN_ID} \
  --enabled-regions ${AWS_REGION} \
  --environment-blueprint-identifier ${TOOLING_ID} \
  --manage-access-role-arn ${ACCESS_ROLE_ARN} \
  --provisioning-role-arn ${PROVISIONING_ROLE_ARN} \
  --region ${AWS_REGION} \
  --no-cli-pager \
  --regional-parameters "${AWS_REGION}={AZs=\"${AZS}\",S3Location=s3://${DOMAIN_S3_BUCKET}/,Subnets=\"${IDS}\",VpcId=${VPC_ID}}"

aws datazone add-policy-grant \
    --detail="{\"createEnvironmentFromBlueprint\":{}}" \
    --domain-identifier ${DOMAIN_ID} \
    --entity-type ENVIRONMENT_BLUEPRINT_CONFIGURATION \
    --entity-identifier ${PRODUCER_ACCOUNT_ID}:${TOOLING_ID} \
    --policy-type CREATE_ENVIRONMENT_FROM_BLUEPRINT \
    --no-cli-pager \
    --principal="{\"project\":{\"projectDesignation\":\"CONTRIBUTOR\",\"projectGrantFilter\":{\"domainUnitFilter\":{\"domainUnit\":\"${ROOT_DOMAIN_UNIT_ID}\",\"includeChildDomainUnits\":true}}}}"
  
# create the project profile
#----------------------------------------------------------------------------------------------------------------
cat ./setup/project-profile-template.json |
    sed "s/\${AWS_REGION}/${AWS_REGION}/g" | \
    sed "s/\${TOOLING_ID}/${TOOLING_ID}/g" | \
    sed "s/\${DATALAKE_ID}/${DATALAKE_ID}/g" | \
    sed "s/\${REDSHIFT_SERVERLESS_ID}/${REDSHIFT_SERVERLESS_ID}/g" | \
    sed "s/\${ACCOUNT_ID}/${PRODUCER_ACCOUNT_ID}/g" > /tmp/project-profile-instance.json

PROFILES=$( aws datazone list-project-profiles --name "ProducerProjectProfile2" --domain-identifier ${DOMAIN_ID} | jq -r '.items[].id' 2>/dev/null )
if [ -z ${PROFILES} ]; then
    echo "Create the producer project profile! "
    aws datazone create-project-profile \
        --description "Default producer project profile offering access to Athena" \
        --domain-identifier ${DOMAIN_ID} \
        --name "ProducerProjectProfile2" \
        --status "ENABLED" \
        --region ${AWS_REGION} \
        --no-cli-pager \
        --environment-configurations file:///tmp/project-profile-instance.json | jq -r '.id' > ./data/producer_project_profile.id
else
  echo "The producer project profile already exists! "
fi
PROJECT_PROFILE_ID=$( cat ./data/producer_project_profile.id )

aws datazone add-policy-grant \
    --detail="{\"createProjectFromProjectProfile\":{\"projectProfiles\":[\"${PROJECT_PROFILE_ID}\"],\"includeChildDomainUnits\":true}}" \
    --domain-identifier ${DOMAIN_ID} \
    --entity-type DOMAIN_UNIT \
    --entity-identifier ${ROOT_DOMAIN_UNIT_ID} \
    --policy-type CREATE_PROJECT_FROM_PROJECT_PROFILE \
    --no-cli-pager \
    --principal="{\"user\":{\"allUsersGrantFilter\":{}}}"

# create the producer project
#----------------------------------------------------------------------------------------------------------------
PROJECTS=$( aws datazone list-projects --name "ProducerProject" --domain-identifier ${DOMAIN_ID} | jq -r '.items[].id' 2>/dev/null )
if [ -z ${PROJECTS} ]; then
    echo "Create the producer project! "
    aws datazone create-project \
    --domain-identifier ${DOMAIN_ID} \
    --name "ProducerProject" \
    --project-profile-id ${PROJECT_PROFILE_ID} \
    --region ${AWS_REGION} \
    --no-cli-pager | jq -r '.id' > ./data/producer_project.id
else
  echo "The producer project already exists! "
fi
PROJECT_ID=$( cat ./data/producer_project.id )

echo "Project creation can take up to 5 minutes, check in the Studio console if the project is created..."


