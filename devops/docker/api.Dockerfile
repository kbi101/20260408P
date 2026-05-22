# Dockerfile for QuantEdge API & Services
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
# Note: In a real scenario, you'd copy a specific requirements.txt
RUN pip install --no-cache-dir fastapi uvicorn "psycopg[pool]" psycopg2-binary requests httpx pandas numpy scipy duckdb pyarrow temporalio redis yfinance questdb ruptures hurst PyWavelets hmmlearn arch aiokafka python-multipart


# Copy source code
# The build context should be the root of the project to access libs
COPY . .

# Set Python path to include libs
ENV PYTHONPATH="/app:/app/libs"

# Default command (can be overridden in docker-compose)
CMD ["uvicorn", "apps.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
