#!/usr/bin/env bash
# S3 Vectors GA — create a vector bucket + index, store vectors, query nearest.
set -euo pipefail
REGION=${REGION:-ap-southeast-1}
BUCKET="whatsnew-demo-vec-$(openssl rand -hex 3)"
IDX=demo-index

aws s3vectors create-vector-bucket --vector-bucket-name "$BUCKET" --region "$REGION"
aws s3vectors create-index --vector-bucket-name "$BUCKET" --index-name "$IDX" \
  --data-type float32 --dimension 4 --distance-metric cosine --region "$REGION"
aws s3vectors put-vectors --vector-bucket-name "$BUCKET" --index-name "$IDX" --region "$REGION" \
  --vectors '[{"key":"apple","data":{"float32":[1.0,0.1,0.0,0.0]}},
              {"key":"banana","data":{"float32":[0.9,0.2,0.1,0.0]}},
              {"key":"car","data":{"float32":[0.0,0.0,1.0,0.9]}}]'
aws s3vectors query-vectors --vector-bucket-name "$BUCKET" --index-name "$IDX" --region "$REGION" \
  --query-vector '{"float32":[1.0,0.15,0.0,0.0]}' --top-k 2 --return-distance

# cleanup
aws s3vectors delete-index --vector-bucket-name "$BUCKET" --index-name "$IDX" --region "$REGION"
aws s3vectors delete-vector-bucket --vector-bucket-name "$BUCKET" --region "$REGION"
