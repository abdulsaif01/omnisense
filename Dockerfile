# OmniSense Local AI Backend Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY omnisense2.0/backend/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code, models, and dependencies
COPY omnisense2.0/backend /app/backend
COPY experiments/models /app/experiments/models

EXPOSE 8080

CMD ["uvicorn", "backend.dev_server:app", "--host", "0.0.0.0", "--port", "8080"]
