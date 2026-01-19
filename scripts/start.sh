#!/bin/bash
set -e

# Prüfe, ob wir in Production/Railway sind
if [ "$NODE_ENV" = "production" ] || [ -n "$RAILWAY_ENVIRONMENT_ID" ]; then
  echo "🚀 Starting in production mode..."
  cd packages/twenty-server
  node dist/main
else
  echo "🔧 Starting in development mode..."
  npx concurrently --kill-others \
    'npx nx run-many -t start -p twenty-server twenty-front' \
    'npx wait-on tcp:3000 && npx nx run twenty-server:worker'
fi
