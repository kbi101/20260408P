#!/bin/bash
set -e

echo "🚀 Deploying QuantEdge Studio Stack..."

# 1. Detect Host IP (Smarter detection for Mac)
HOST_IP=$(python3 -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); print(s.getsockname()[0]); s.close()" || ipconfig getifaddr en0 || ipconfig getifaddr en1)
echo "🌐 Detected Host IP: $HOST_IP"

if [ -z "$HOST_IP" ]; then
    echo "⚠️ Warning: Could not detect Host IP. Falling back to host.docker.internal"
    HOST_IP="host.docker.internal"
fi

# 2. Preparation: Logic Build
./devops/scripts/build.sh

# 3. Preparation: Database & Temporal Schema (Skipped - Manually Prepared)

# 4. Orchestration Deployment
echo "🧹 Cleaning up old containers..."
/usr/local/bin/docker-compose --env-file .env.local down

echo "🚢 Launching services..."
export HOST_IP=$HOST_IP
/usr/local/bin/docker-compose --env-file .env.local up -d --build

echo "📊 Checking service status..."
sleep 10
/usr/local/bin/docker-compose ps

echo "✨ Deployment complete. Local UI: http://localhost:3100"
