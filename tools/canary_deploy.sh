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

if [[ $REPO_BRANCH == "develop" ]]
then
    echo "sending webhook..."
    WEBHOOK_URL="https://api.dev1.clutchtech.io/canary-service/webhook"
    curl -f -X -POST -H "Content-Type: application/json" -H "X-Github-Webhook-API-Key: $API_KEY" --data "{ \"target\": \"$REPO_NAME\", \"imageId\": \"$IMAGE_ID\" }" $WEBHOOK_URL || echo "curl call failed"
fi