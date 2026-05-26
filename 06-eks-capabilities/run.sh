#!/usr/bin/env bash
# EKS Capabilities (GA) — managed Argo CD / ACK / KRO running OUTSIDE the cluster.
# NOTE: not run live in this edition (needs a real cluster + Identity Center).
# A full hands-on (create cluster -> enable capability -> deploy via managed Argo CD)
# is planned for a later edition. Reference command:
aws eks create-capability \
  --cluster-name my-cluster \
  --name my-argocd \
  --type ARGOCD \
  --role-arn "$CAPABILITY_ROLE_ARN" \
  --delete-propagation-policy RETAIN
# Docs: https://docs.aws.amazon.com/eks/latest/userguide/argocd-create-cli.html
