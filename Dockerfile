# TriageAI — Cloud Run Dockerfile
# Builds a single container: React frontend (served as static files by Flask)
# Deployed on Google Cloud Run as required by the Google AI Ecosystem Stack mandate.

# ── Stage 1: Build React frontend ──────────────────────────────────────────
FROM node:20-slim AS frontend-build

WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --silent
COPY frontend/ ./
RUN npm run build          
# Outputs to /app/frontend/dist

# ── Stage 2: Python backend + embedded static frontend ────────────────────
FROM python:3.11-slim

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Backend source
COPY backend/ ./backend/

# Copy compiled React app into backend static folder
COPY --from=frontend-build /app/frontend/dist ./backend/static/

# Cloud Run injects PORT env var (default 8080)
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

WORKDIR /app/backend

# Gunicorn: production WSGI server
CMD exec gunicorn \
    --bind "0.0.0.0:${PORT}" \
    --workers 2 \
    --threads 4 \
    --timeout 60 \
    server:app
