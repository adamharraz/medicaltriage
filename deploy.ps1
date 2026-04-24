# TriageAI — Windows Deployment Script for Google Cloud Run
# Requires: gcloud CLI authenticated

$ErrorActionPreference = "Continue"

# 1. Configuration
$GCLOUD_PATH = "C:\Users\muham\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
if (Test-Path $GCLOUD_PATH) {
    $GCLOUD = $GCLOUD_PATH
    Write-Host "Using gcloud at: $GCLOUD"
} else {
    $GCLOUD = "gcloud"
}

$PROJECT_ID = "medicaltriage"
$REGION = "asia-southeast1"
$SERVICE = "triageai-app"
$REPO = "triageai"
$IMAGE = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${SERVICE}"

Write-Host "==============================================="
Write-Host "   TriageAI - Deploying to Google Cloud Run   "
Write-Host "==============================================="
Write-Host "  Project : $PROJECT_ID"
Write-Host "  Region  : $REGION"
Write-Host "  Service : $SERVICE"
Write-Host "==============================================="

# 2. Ensure Artifact Registry repo exists
Write-Host "[1/4] Ensuring Artifact Registry repository..."
& $GCLOUD artifacts repositories create $REPO --repository-format=docker --location=$REGION --project $PROJECT_ID 2>$null

# 3. Store API key in Secret Manager
Write-Host "[2/4] Checking GEMINI_API_KEY secret..."
$secretExists = $false
try {
    & $GCLOUD secrets describe GEMINI_API_KEY --project $PROJECT_ID 2>$null
    if ($LASTEXITCODE -eq 0) { $secretExists = $true }
} catch {
    $secretExists = $false
}

if (-not $secretExists) {
    Write-Host "  Creating GEMINI_API_KEY secret..."
    $env_content = Get-Content "backend\.env"
    $key_line = $env_content | Select-String "GEMINI_API_KEY="
    if ($key_line) {
        $API_KEY = $key_line.ToString().Split("=")[1].Trim()
        [IO.File]::WriteAllText("$PSScriptRoot\temp_key.txt", $API_KEY)
        & $GCLOUD secrets create GEMINI_API_KEY --data-file="$PSScriptRoot\temp_key.txt" --project $PROJECT_ID
        Remove-Item "$PSScriptRoot\temp_key.txt" -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  Updating GEMINI_API_KEY secret with new version..."
    $env_content = Get-Content "backend\.env"
    $key_line = $env_content | Select-String "GEMINI_API_KEY="
    if ($key_line) {
        $API_KEY = $key_line.ToString().Split("=")[1].Trim()
        [IO.File]::WriteAllText("$PSScriptRoot\temp_key.txt", $API_KEY)
        & $GCLOUD secrets versions add GEMINI_API_KEY --data-file="$PSScriptRoot\temp_key.txt" --project $PROJECT_ID
        Remove-Item "$PSScriptRoot\temp_key.txt" -ErrorAction SilentlyContinue
    }
}

# 3.5. Read Model Name
$MODEL_NAME = "gemini-2.0-flash"
$model_line = Get-Content "backend\.env" | Select-String "GEMINI_MODEL="
if ($model_line) {
    $MODEL_NAME = $model_line.ToString().Split("=")[1].Trim()
}
Write-Host "  Using model: $MODEL_NAME"

# 4. Build and push Docker image via Cloud Build
Write-Host "[3/4] Building image with Cloud Build..."
& $GCLOUD builds submit --tag "${IMAGE}:latest" --region=$REGION --project $PROJECT_ID .

# 5. Deploy to Cloud Run
Write-Host "[4/4] Deploying to Cloud Run..."
& $GCLOUD run deploy $SERVICE `
  --image="${IMAGE}:latest" `
  --region=$REGION `
  --platform=managed `
  --allow-unauthenticated `
  --port=8080 `
  --memory=1Gi `
  --cpu=1 `
  --min-instances=0 `
  --max-instances=10 `
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest" `
  --set-env-vars="GEMINI_MODEL=$MODEL_NAME" `
  --project $PROJECT_ID

$SERVICE_URL = & $GCLOUD run services describe $SERVICE --region=$REGION --format='value(status.url)' --project $PROJECT_ID

Write-Host "-----------------------------------------------"
Write-Host "Deployed successfully!"
Write-Host "Service URL: $SERVICE_URL"
Write-Host "-----------------------------------------------"
