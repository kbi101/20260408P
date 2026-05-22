# Specialized Dockerfile for the Dynamic Ingestion Worker (v2.0)
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for financial libs and networking
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install core ingestion dependencies
RUN pip install --no-cache-dir \
    temporalio \
    redis \
    yfinance \
    psycopg[binary] \
    questdb \
    pandas \
    numpy \
    requests \
    python-dateutil \
    duckdb \
    pyarrow \
    scipy \
    lightgbm \
    scikit-learn \
    PyWavelets \
    hmmlearn \
    arch \
    httpx \
    aiokafka


# Copy shared libraries and worker source
COPY libs/ /app/libs/
COPY services/worker/ /app/services/worker/

# Set Python path to include libs
ENV PYTHONPATH="/app:/app/libs"

# Start the Temporal Worker
CMD ["python", "services/worker/main.py"]
