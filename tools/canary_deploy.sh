#!/usr/bin/env bash

if [[ -z "$1" ]]
then
      echo "\$CIRCLE_BRANCH is empty"
fi

if [[ -z "$2" ]]
then
      echo "\$CIRCLE_SHA1 is empty"
      exit 1
fi

if [[ -z "$3" ]]
then
      echo "\$CIRCLE_PROJECT_REPONAME is empty"
      exit 1
fi

if [[ -z "$4" ]]
then
      echo "\$API_KEY is empty"
      exit 1
fi

REPO_BRANCH=$1
IMAGE_ID=$2
REPO_NAME=$3
API_KEY=$4

generate_post_data()
{
  cat <<EOF
{
  "imageId": "$IMAGE_ID",
  "target": "$REPO_NAME"
}
EOF
}

if [[ $REPO_BRANCH == "develop" ]]
then
    WEBHOOK_URL="https://api.dev1.clutchtech.io/canary-service/webhook"
    curl --location --request POST $WEBHOOK_URL \
      --header 'Content-Type: application/json' \
      --header "X-Github-Webhook-API-Key: $API_KEY" \
      --data "$(generate_post_data)"
fi
