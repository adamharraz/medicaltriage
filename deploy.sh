#!/bin/bash
# TriageAI — One-command Google Cloud Run deployment
# Requires: gcloud CLI authenticated, PROJECT_ID set

set -e

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
REGION="asia-southeast1"
SERVICE="triageai-app"
REPO="triageai"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${SERVICE}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   TriageAI — Deploying to Google Cloud Run   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Project : ${PROJECT_ID}"
echo "  Region  : ${REGION} (Malaysia-adjacent)"
echo "  Service : ${SERVICE}"
echo ""

# 1. Ensure Artifact Registry repo exists
echo "[1/4] Ensuring Artifact Registry repository..."
gcloud artifacts repositories create ${REPO} \
  --repository-format=docker \
  --location=${REGION} \
  --quiet 2>/dev/null || true

# 2. Store API key in Secret Manager (first time only)
if ! gcloud secrets describe GEMINI_API_KEY --quiet 2>/dev/null; then
  echo "[2/4] Creating GEMINI_API_KEY secret in Secret Manager..."
  if [ -z "$GEMINI_API_KEY" ]; then
    echo "  ERROR: GEMINI_API_KEY env var not set."
    echo "  Run: export GEMINI_API_KEY=AIza..."
    exit 1
  fi
  echo -n "$GEMINI_API_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=-
else
  echo "[2/4] GEMINI_API_KEY secret already exists in Secret Manager ✓"
fi

# 3. Build and push Docker image via Cloud Build
echo "[3/4] Building image with Cloud Build..."
gcloud builds submit \
  --tag "${IMAGE}:latest" \
  --region="${REGION}" \
  .

# 4. Deploy to Cloud Run
echo "[4/4] Deploying to Cloud Run..."
gcloud run deploy ${SERVICE} \
  --image="${IMAGE}:latest" \
  --region="${REGION}" \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest"

SERVICE_URL=$(gcloud run services describe ${SERVICE} --region=${REGION} --format='value(status.url)')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployed successfully!"
echo ""
echo "   Patient Kiosk  : ${SERVICE_URL}/kiosk"
echo "   Nurse Dashboard: ${SERVICE_URL}/nurse"
echo "   API Health     : ${SERVICE_URL}/api/health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
