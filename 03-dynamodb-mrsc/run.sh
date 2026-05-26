#!/usr/bin/env bash
# DynamoDB Multi-Region Strong Consistency (MRSC).
# Needs exactly 3 participants in supported Regions (US group shown here).
set -euo pipefail
T=mrsc-demo
aws dynamodb create-table --table-name "$T" \
  --attribute-definitions AttributeName=PK,AttributeType=S \
  --key-schema AttributeName=PK,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-2
aws dynamodb wait table-exists --table-name "$T" --region us-east-2

# Enable MRSC: replica + witness + STRONG. Retry once if you hit a transient
# UnrecognizedClientException right after the table becomes active.
aws dynamodb update-table --table-name "$T" --region us-east-2 \
  --replica-updates '[{"Create":{"RegionName":"us-east-1"}}]' \
  --global-table-witness-updates '[{"Create":{"RegionName":"us-west-2"}}]' \
  --multi-region-consistency STRONG

# Wait until the replica is ACTIVE, then:
aws dynamodb put-item --table-name "$T" --region us-east-2 \
  --item '{"PK":{"S":"song#hey-jude"},"plays":{"N":"100"}}'
aws dynamodb get-item --table-name "$T" --region us-east-1 \
  --key '{"PK":{"S":"song#hey-jude"}}' --consistent-read   # immediate, strong

# cleanup: delete replica+witness, wait, delete primary
aws dynamodb update-table --table-name "$T" --region us-east-2 \
  --replica-updates '[{"Delete":{"RegionName":"us-east-1"}}]' \
  --global-table-witness-updates '[{"Delete":{"RegionName":"us-west-2"}}]'
sleep 60
aws dynamodb delete-table --table-name "$T" --region us-east-2
