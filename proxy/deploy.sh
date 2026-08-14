#!/usr/bin/env bash
# Deploy the AuraLearn proxy to Cloud Run.
#
# Pattern mirrors the yijing server/deploy.sh: gcloud builds submit + run
# deploy, secrets from Secret Manager, auth at the application layer
# (--allow-unauthenticated; every route verifies the Firebase ID token).
#
# Requires:
#   - gcloud CLI with a project set (gcloud config set project <id>)
#   - Cloud Run + Secret Manager APIs enabled
#   - Secret Manager versions created (see README "Cloud Run deployment"):
#       ANTHROPIC_API_KEY, OPENAI_API_KEY, REVENUECAT_API_KEY,
#       REVENUECAT_WEBHOOK_SECRET, REVENUECAT_WEBHOOK_HMAC_SECRET
#     (only the providers/tiers you actually use are needed — but this script
#     mounts all five, so create placeholders for the unused ones)
#   - FIREBASE_PROJECT_ID in the environment (the Firebase project id — the
#     proxy verifies Firebase ID tokens against it)
set -euo pipefail

REGION=${REGION:-asia-southeast1}
SERVICE=${SERVICE:-auralearn-proxy}
PROJECT=$(gcloud config get-value project)
IMAGE=gcr.io/${PROJECT}/auralearn-proxy

if [ -z "${FIREBASE_PROJECT_ID:-}" ]; then
  echo "ERROR: set FIREBASE_PROJECT_ID (the Firebase project id) before deploying." >&2
  exit 1
fi

echo "==> Building $IMAGE"
gcloud builds submit --tag "$IMAGE"

echo "==> Deploying $SERVICE"
gcloud run deploy "$SERVICE" \
  --image "$IMAGE" \
  --platform managed \
  --region "$REGION" \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 3 \
  --concurrency 40 \
  --timeout 300 \
  --allow-unauthenticated \
  --set-secrets="ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest" \
  --set-secrets="OPENAI_API_KEY=OPENAI_API_KEY:latest" \
  --set-secrets="REVENUECAT_API_KEY=REVENUECAT_API_KEY:latest" \
  --set-secrets="REVENUECAT_WEBHOOK_SECRET=REVENUECAT_WEBHOOK_SECRET:latest" \
  --set-secrets="REVENUECAT_WEBHOOK_HMAC_SECRET=REVENUECAT_WEBHOOK_HMAC_SECRET:latest" \
  --update-env-vars="FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}" \
  --update-env-vars="FREE_DAILY_QUOTA=${FREE_DAILY_QUOTA:-3}" \
  --update-env-vars="DEV_AUTH_TOKEN="

echo "==> Done. Service URL:"
gcloud run services describe "$SERVICE" --platform managed --region "$REGION" \
  --format="value(status.url)"
