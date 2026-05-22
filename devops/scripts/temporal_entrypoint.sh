#!/bin/bash
set -e

# Fixed Entrypoint (Bypassing Shell Helper)
echo "🚀 QuantEdge Direct-Fire Bootstrap starting..."

# Inject the standard auto-setup environment
export DB_PORT=${SQL_PORT:-5432}
export DB_HOST=${SQL_HOST:-host.docker.internal}

# Directly invoke the core server binary
# This skips the 'auto-setup.sh' logic and its problematic loops
./temporal-server start --allow-no-auth
