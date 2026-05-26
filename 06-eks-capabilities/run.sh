#!/usr/bin/env bash
# EKS Capabilities (GA) — managed Argo CD running OUTSIDE the cluster.
# Prereqs: eksctl, kubectl, and AWS Identity Center already enabled (Argo CD
# capability REQUIRES Identity Center — local users are not supported).
set -euo pipefail
REGION=${REGION:-ap-southeast-1}
CLUSTER=whatsnew-eks
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# 1) IAM capability role (trusted by the EKS capabilities service)
cat > /tmp/argocd-trust.json <<'JSON'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow",
 "Principal":{"Service":"capabilities.eks.amazonaws.com"},
 "Action":["sts:AssumeRole","sts:TagSession"]}]}
JSON
aws iam create-role --role-name ArgoCDCapabilityRole \
  --assume-role-policy-document file:///tmp/argocd-trust.json

# 2) A small cluster (~15 min)
eksctl create cluster --name "$CLUSTER" --region "$REGION" \
  --nodegroup-name ng --node-type t3.small --nodes 1 --managed

# 3) Identity Center instance + a user id for the RBAC mapping
IDC_INSTANCE_ARN=$(aws sso-admin list-instances --region "$REGION" --query 'Instances[0].InstanceArn' --output text)
STORE=$(aws sso-admin list-instances --region "$REGION" --query 'Instances[0].IdentityStoreId' --output text)
IDC_USER_ID=$(aws identitystore list-users --identity-store-id "$STORE" --region "$REGION" \
  --query 'Users[0].UserId' --output text)

# 4) Create the managed Argo CD capability
aws eks create-capability --region "$REGION" --cluster-name "$CLUSTER" \
  --capability-name my-argocd --type ARGOCD \
  --role-arn "arn:aws:iam::${ACCOUNT}:role/ArgoCDCapabilityRole" \
  --delete-propagation-policy RETAIN \
  --configuration "{\"argoCd\":{\"awsIdc\":{\"idcInstanceArn\":\"$IDC_INSTANCE_ARN\",\"idcRegion\":\"$REGION\"},\"rbacRoleMappings\":[{\"role\":\"ADMIN\",\"identities\":[{\"id\":\"$IDC_USER_ID\",\"type\":\"SSO_USER\"}]}]}}"

# 5) Wait ACTIVE, then confirm Argo CD CRDs landed in the cluster
until [ "$(aws eks describe-capability --region "$REGION" --cluster-name "$CLUSTER" \
  --capability-name my-argocd --query 'capability.status' --output text)" = "ACTIVE" ]; do sleep 20; done
kubectl api-resources | grep argoproj.io   # Application, ApplicationSet, AppProject

# 6) Cleanup
aws eks delete-capability --region "$REGION" --cluster-name "$CLUSTER" --capability-name my-argocd
eksctl delete cluster --name "$CLUSTER" --region "$REGION"
aws iam delete-role --role-name ArgoCDCapabilityRole
