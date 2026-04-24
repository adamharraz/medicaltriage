# 🏥 TriageAI

> **AI-powered emergency department triage — Malaysian Triage Scale, multi-agent swarm, real-time nurse dashboard.**

[![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)](https://python.org)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev)
[![Flask](https://img.shields.io/badge/Flask-3.x-black?logo=flask)](https://flask.palletsprojects.com)
[![Gemini](https://img.shields.io/badge/LLM-Gemini--3.1--Flash--Lite--Preview-blue)](https://ai.google.dev)
[![CloudRun](https://img.shields.io/badge/Deploy-Cloud_Run-4285F4?logo=googlecloud)](https://cloud.google.com/run)
[![XGBoost](https://img.shields.io/badge/ML-XGBoost-red)](https://xgboost.readthedocs.io)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-4-38BDF8?logo=tailwindcss)](https://tailwindcss.com)

---

## 🚨 The Problem

Emergency departments are overwhelmed. Nurses manually assess every patient on arrival — a slow, error-prone process that is especially critical when time is measured in minutes. A single misclassification can cost a life.

**TriageAI** augments the triage nurse with a multi-agent AI swarm that analyses vitals, symptoms, and visual flags in parallel, then synthesises a clinically-reasoned zone decision in seconds — using the official **Malaysian Triage Scale (MTS)**.

---

## ✨ What It Does

| Role | Experience |
|---|---|
| 🧑‍⚕️ **Patient** | Self-checks in at a kiosk — enters symptoms, vitals, and visual flags via a guided form |
| 🖥️ **Patient Display** | Receives a plain-language explanation of their triage zone and expected wait time |
| 👩‍⚕️ **Nurse** | Sees a live dashboard with the AI's zone decision, confidence score, clinical narrative, and full agent reasoning |

---

## 🧠 How It Works — The AI Swarm

A five-agent pipeline runs on every patient submission:

```
Patient Input (vitals + symptoms + visual flags)
         │
         ▼
  [XGBoost ML]  ──→  initial zone signal
         │
         ▼
  [ORCHESTRATOR]
    ┌────┴────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐
    │ VITALS  │  │ SYMPTOM  │  │  VISUAL  │  │   RISK    │
    │  AGENT  │  │  AGENT   │  │  AGENT   │  │   AGENT   │
    └────┬────┘  └────┬─────┘  └────┬─────┘  └─────┬─────┘
         └────────────┴─────────────┴───────────────┘
                                │
                       [COORDINATOR AGENT]
                                │
                     Final triage result:
                     • Zone 1–5 + colour
                     • Confidence %
                     • Clinical narrative (nurse)
                     • Patient explanation (display screen)
                     • Flag reasons + escalation alerts
```

**Each agent is a specialist:**

- **Vitals Agent** — Analyses heart rate, BP, SpO₂, temperature, respiratory rate
- **Symptom Agent** — Interprets reported complaints and onset patterns
- **Visual Agent** — Evaluates physical appearance flags (pallor, diaphoresis, distress level, etc.)
- **Risk Agent** — Cross-signal pattern detector; flags edge cases and escalation triggers
- **Coordinator Agent** — Senior ED physician persona; synthesises all agents + XGBoost into a final authoritative decision

---

## 🗂️ Project Structure

```
triageai/
├── Dockerfile                      ← multi-stage build (Node + Python)
├── cloudbuild.yaml                 ← Google Cloud Build CI/CD pipeline
├── deploy.ps1                      ← Windows deployment script (Cloud Run)
├── deploy.sh                       ← Linux/macOS deployment script
├── backend/
│   ├── server.py                   ← Flask REST API + static frontend serving
│   ├── triage_engine.py            ← XGBoost inference
│   ├── models.py                   ← Pydantic schemas
│   ├── generate_training_data.py   ← synthetic training data generator
│   ├── train_model.py              ← XGBoost model trainer
│   ├── agents/
│   │   ├── orchestrator.py         ← fans out to all agents in parallel
│   │   ├── vitals_agent.py
│   │   ├── symptom_agent.py
│   │   ├── visual_agent.py
│   │   ├── risk_agent.py
│   │   └── coordinator.py          ← final decision synthesiser
│   ├── tools/
│   │   └── gemini_utils.py         ← Gemini API + JSON parsing
│   └── requirements.txt
└── frontend/                       ← React 19 + Vite 8 + Tailwind CSS 4
    └── src/
        ├── App.jsx                 ← route definitions
        ├── api.js                  ← backend API client
        ├── index.css               ← global styles
        ├── pages/
        │   ├── LandingPage.jsx
        │   ├── KioskPage.jsx           ← patient self-check-in
        │   ├── PatientDisplayPage.jsx  ← patient-facing result screen
        │   └── NurseDashboardPage.jsx  ← live queue + AI reasoning panel
        └── components/
            ├── ClinicalShell.jsx       ← shared layout shell with navigation
            ├── SwarmPanel.jsx          ← visualises all agent outputs
            ├── VitalsForm.jsx
            ├── SymptomQuestionnaire.jsx
            ├── VisualFlagsForm.jsx
            ├── BodyMap.jsx             ← pain location selector
            ├── ExplanationCard.jsx     ← patient-facing explanation display
            └── ZoneBadge.jsx
```

---

## ⚡ Quick Start

### Prerequisites

- Python 3.11+
- Node.js 20+
- A [Google Gemini API key](https://aistudio.google.com/app/apikey)
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install) *(for deployment only)*

### 1. Clone & configure

```bash
git clone https://github.com/adamharraz/medicaltriage.git
cd medicaltriage
```

```bash
# Set your API key (choose one)
export GEMINI_API_KEY=AIza...
# or
echo "GEMINI_API_KEY=AIza..." > backend/.env
```

### 2. Run locally

**Backend:**

```bash
cd backend
pip install -r requirements.txt
python server.py
```

**Frontend** (in a separate terminal):

```bash
cd frontend
npm install
npm run dev
```

The frontend dev server proxies `/api` requests to `http://localhost:8080` automatically.

### 3. (Optional) Train the XGBoost model

```bash
cd backend
python generate_training_data.py   # creates data/training_data.csv
python train_model.py              # trains & saves model to model/
```

> If skipped, the server falls back to Zone 3 as the ML signal — the AI swarm still runs fully.

---

## 🚀 Deploy to Google Cloud Run

The app ships as a single Docker container — the React frontend is built and served as static files by Flask via Gunicorn.

### Automated deployment

Ensure you have authenticated with `gcloud auth login` and linked a billing account.

```bash
# Windows
.\deploy.ps1

# Linux/macOS
./deploy.sh
```

### CI/CD via Cloud Build

The `cloudbuild.yaml` pipeline automatically:
1. Builds the multi-stage Docker image
2. Pushes to Google Artifact Registry (`asia-southeast1`)
3. Deploys to Cloud Run with secret injection

Trigger it on push to `main` via [Google Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers).

### Docker (manual)

```bash
docker build -t triageai .
docker run -p 8080:8080 -e GEMINI_API_KEY=AIza... triageai
```

---

## 🔌 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Service health check |
| `POST` | `/api/triage` | Submit patient data, run AI swarm |
| `GET` | `/api/patients` | List all active waiting patients |
| `GET` | `/api/patients/<id>` | Get single patient record |
| `PATCH` | `/api/patients/<id>/override` | Nurse manual zone override |
| `DELETE` | `/api/patients/<id>` | Discharge patient |
| `GET` | `/api/queue-stats` | Zone counts + flagged count |
| `GET` | `/api/demo` | Mock result for UI testing (no API calls) |

---

## 🇲🇾 Malaysian Triage Scale

| Zone | Colour | Urgency | Target Time |
|---|---|---|---|
| 1 | 🔴 Red | Life-threatening — immediate resuscitation | Immediate |
| 2 | 🟠 Orange | Very urgent — may deteriorate rapidly | ≤ 10 min |
| 3 | 🟡 Yellow | Urgent — stable but requires prompt attention | ≤ 30 min |
| 4 | 🟢 Green | Semi-urgent — minor illness or injury | ≤ 60 min |
| 5 | 🔵 Blue | Non-urgent — suitable for GP or clinic | ≤ 120 min |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| LLM | Gemini 3.1 Flash Lite Preview via `google-generativeai` SDK |
| ML Model | XGBoost (trained on 6,000-row synthetic MTS dataset) |
| Backend | Python 3.11, Flask 3, Pydantic 2, Gunicorn |
| Frontend | React 19, Vite 8, Tailwind CSS 4, React Router 7 |
| Agent Framework | Custom multi-agent swarm (no LangChain) |
| Deployment | Google Cloud Run, Cloud Build, Artifact Registry |
| Container | Multi-stage Docker (Node 20 + Python 3.11) |

---

## 🌱 Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | ✅ Yes | Google Gemini API key |
| `GEMINI_MODEL` | No | Model name override (default: `gemini-3.1-flash-lite-preview`) |
| `PORT` | No | Flask/Gunicorn port (default: `8080`) |
| `FLASK_ENV` | No | Set to `development` for debug mode |
