#!/usr/bin/env bash
# Bedrock — invoke new open-weight models via the unified Converse API.
set -euo pipefail
REGION=${REGION:-us-east-1}

aws bedrock list-foundation-models --region "$REGION" \
  --query "modelSummaries[?contains(modelId,'qwen')||contains(modelId,'gpt-oss')].modelId"

# Qwen3 (text)
aws bedrock-runtime converse --region "$REGION" --model-id "qwen.qwen3-32b-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Reply in 5 words: why use serverless?"}]}]' \
  --inference-config '{"maxTokens":60}'

# gpt-oss is a reasoning model: content = [reasoningContent, text]
aws bedrock-runtime converse --region "$REGION" --model-id "openai.gpt-oss-20b-1:0" \
  --messages '[{"role":"user","content":[{"text":"In one sentence: what is a Lambda cold start?"}]}]' \
  --inference-config '{"maxTokens":200}' --query 'output.message.content'
