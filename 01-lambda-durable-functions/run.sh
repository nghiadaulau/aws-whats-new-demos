#!/usr/bin/env bash
# Lambda Durable Functions — step + wait (10s) + replay-aware logging.
set -euo pipefail
REGION=${REGION:-ap-southeast-1}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# 1) Execution role with the durable-execution managed policy
aws iam create-role --role-name durable-demo-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name durable-demo-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicDurableExecutionRolePolicy
sleep 8  # let the role propagate

# 2) Package (index.mjs uses @aws/durable-execution-sdk-js)
npm install
zip -rq function.zip index.mjs node_modules/

# 3) Create the function — --durable-config activates durable execution
aws lambda create-function --function-name durable-demo --runtime nodejs22.x \
  --role "arn:aws:iam::${ACCOUNT}:role/durable-demo-role" --handler index.handler \
  --zip-file fileb://function.zip \
  --durable-config '{"ExecutionTimeout": 900, "RetentionPeriodInDays": 1}' --region "$REGION"
aws lambda wait function-active --function-name durable-demo --region "$REGION"

# 4) Invoke (takes ~10s because of the wait), then check replay-aware logs
time aws lambda invoke --function-name 'durable-demo:$LATEST' \
  --cli-binary-format raw-in-base64-out --payload '{}' --region "$REGION" response.json
cat response.json
sleep 5
aws logs tail "/aws/lambda/durable-demo" --region "$REGION" --since 5m \
  | grep -oE '"message":"[^"]*"' | sort | uniq -c

# 5) Cleanup
aws lambda delete-function --function-name durable-demo --region "$REGION"
aws logs delete-log-group --log-group-name "/aws/lambda/durable-demo" --region "$REGION" || true
aws iam detach-role-policy --role-name durable-demo-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicDurableExecutionRolePolicy
aws iam delete-role --role-name durable-demo-role
