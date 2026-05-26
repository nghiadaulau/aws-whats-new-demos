#!/usr/bin/env bash
# Security Hub (GA, near real-time risk analytics) — quick CLI check.
# The new risk-analytics value is mostly in the console; CLI just confirms it's on.
set -euo pipefail
REGION=${REGION:-ap-southeast-1}
aws securityhub enable-security-hub --region "$REGION"
aws securityhub describe-hub --region "$REGION" \
  --query '{HubArn:HubArn,SubscribedAt:SubscribedAt,AutoEnableControls:AutoEnableControls}'
aws securityhub get-enabled-standards --region "$REGION" --query 'length(StandardsSubscriptions)'
aws securityhub disable-security-hub --region "$REGION"   # turn off to avoid charges when just trying
