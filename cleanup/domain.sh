#!/bin/zsh

# switch to the domain/producer account credentials
#----------------------------------------------------------------------------------------------------------------
export AWS_ACCESS_KEY_ID=${PRODUCER_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${PRODUCER_AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${PRODUCER_AWS_SESSION_TOKEN}

# delete the domain
#----------------------------------------------------------------------------------------------------------------
aws datazone delete-domain --identifier $( cat ./data/domain.id ) --skip-deletion-check --region ${AWS_REGION}
