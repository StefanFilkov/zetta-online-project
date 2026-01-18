#!/bin/bash

export $(grep -v '^#' .env | sed 's/\r$//' | xargs)
gcloud services enable cloudfunctions.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    vpcaccess.googleapis.com \
    --project $PROJECT_ID

gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
    --region $REGION \
    --range 10.8.0.0/28 \
    --network $NETWORK_NAME \
    --project $PROJECT_ID || echo "Connector likely exists, skipping creation."

gcloud functions deploy audit-vpcs \
    --gen2 \
    --runtime python311 \
    --region $REGION \
    --source ./audit-function \
    --entry-point list_vpcs_and_subnets \
    --trigger-http \
    --allow-unauthenticated \
    --vpc-connector $CONNECTOR_NAME \
    --set-env-vars PROJECT_ID=$PROJECT_ID,DB_USER=$DB_USER,DB_PASS=$DB_PASS,DB_NAME=$DB_NAME \
    --project $PROJECT_ID
