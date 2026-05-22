#!/bin/bash
set -e
# QuantEdge Studio - Unified Build Script

echo "🚀 Starting QuantEdge Build Process..."

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Build Frontend
echo "📦 Building Frontend Image..."
/usr/local/bin/docker build -t quantedge-frontend -f devops/docker/frontend.Dockerfile .

# Build API
echo "🔌 Building API Image..."
/usr/local/bin/docker build -t quantedge-api -f devops/docker/api.Dockerfile .

# Build Worker
echo "⚙️ Building Worker Image..."
/usr/local/bin/docker build -t quantedge-worker -f devops/docker/worker.Dockerfile .

echo "✅ All images built successfully!"
