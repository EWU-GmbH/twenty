#!/bin/sh
set -e

# Prüfe, ob wir in Production/Railway sind
if [ "$NODE_ENV" = "production" ] || [ -n "$RAILWAY_ENVIRONMENT_ID" ]; then
  echo "=== Production Mode Startup ===" >&2
  # Stelle sicher, dass wir im Root-Verzeichnis sind
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  cd "$PROJECT_ROOT/packages/twenty-server"

  echo "Current directory: $(pwd)" >&2

  # Prüfe, ob das Frontend-Verzeichnis existiert
  if [ ! -d "dist/front" ]; then
    echo "ERROR: Frontend directory not found at dist/front" >&2
    echo "Contents of dist:" >&2
    ls -la dist/ 2>&1 || echo "dist directory does not exist" >&2
    echo "Contents of packages/twenty-front/build:" >&2
    ls -la "$PROJECT_ROOT/packages/twenty-front/build/" 2>&1 || echo "Frontend build directory does not exist" >&2
  else
    echo "SUCCESS: Frontend directory found at dist/front" >&2
    echo "Frontend files:" >&2
    ls -la dist/front/ | head -20 >&2
  fi

  exec node dist/main
else
  echo "🔧 Starting in development mode..."
  npx concurrently --kill-others \
    'npx nx run-many -t start -p twenty-server twenty-front' \
    'npx wait-on tcp:3000 && npx nx run twenty-server:worker'
fi
