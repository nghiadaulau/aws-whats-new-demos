# aws-whats-new-demos

Hands-on demos for the **"AWS Mỗi Tháng" (AWS Monthly What's New)** blog series — a
recurring digest of notable new AWS features, with the demoable ones actually run on
real AWS and torn down afterward.

Each folder is one feature. Scripts use the AWS CLI and clean up after themselves.

| # | Feature | What it shows | Cost |
|---|---------|---------------|------|
| 01 | **Lambda Durable Functions** | `step` + `wait` (10s, no compute charge) + replay-aware logging | ~$0 |
| 02 | **S3 Vectors** | vector bucket + index, store vectors, nearest-neighbour query | ~$0 |
| 03 | **DynamoDB Multi-Region Strong Consistency** | 3-participant global table, write in one Region → strong read in another, immediately | small |
| 04 | **Bedrock open-weight models** | invoke Qwen3 and gpt-oss through the unified Converse API | tiny (tokens) |
| 05 | **Security Hub (GA)** | enable → describe → disable (the real value is the console) | ~$0 if disabled right away |
| 06 | **EKS Capabilities** | managed Argo CD reference command (full cluster demo planned for a later edition) | — |

## Run

```bash
# pick a folder, then:
REGION=ap-southeast-1 bash NN-*/run.sh
```

Notes:
- DynamoDB MRSC only works in supported Regions (US group: us-east-2 / us-east-1 / us-west-2).
- Bedrock open-weight models: use us-east-1 for the widest model availability.
- Every script tears down its resources. Double-check your account afterward.

Region/account in examples is masked (`111122223333`) where it appears.
