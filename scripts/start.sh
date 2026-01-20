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

  # Railway setzt automatisch PORT - verwende es für NODE_PORT
  # PORT hat Priorität, falls es gesetzt ist (Railway setzt es automatisch)
  if [ -n "$PORT" ]; then
    export NODE_PORT="$PORT"
    echo "✅ Using Railway PORT ($PORT) for NODE_PORT" >&2
  else
    echo "⚠️  PORT not set, using NODE_PORT: ${NODE_PORT:-3000}" >&2
  fi

  echo "Final NODE_PORT: $NODE_PORT" >&2
  echo "Railway PORT: ${PORT:-not set}" >&2

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

  # Prüfe, ob dist/main.js oder dist/main existiert
  # NestJS kann beide Formate kompilieren
  echo "Checking for main file..." >&2
  echo "  - Checking dist/main.js: $([ -f "dist/main.js" ] && echo "EXISTS" || echo "NOT FOUND")" >&2
  echo "  - Checking dist/main: $([ -f "dist/main" ] && echo "EXISTS" || echo "NOT FOUND")" >&2

  if [ -f "dist/main.js" ]; then
    MAIN_FILE="dist/main.js"
    echo "✅ Found dist/main.js" >&2
  elif [ -f "dist/main" ]; then
    MAIN_FILE="dist/main"
    echo "✅ Found dist/main" >&2
  else
    echo "❌ ERROR: Neither dist/main.js nor dist/main found!" >&2
    echo "Contents of dist:" >&2
    ls -la dist/ 2>&1 | head -50 >&2
    exit 1
  fi

  echo "Starting server with NODE_PORT=$NODE_PORT..." >&2
  echo "Environment check:" >&2
  echo "  - NODE_ENV: ${NODE_ENV:-not set}" >&2
  echo "  - RAILWAY_ENVIRONMENT_ID: ${RAILWAY_ENVIRONMENT_ID:-not set}" >&2
  echo "  - PORT: ${PORT:-not set}" >&2
  echo "  - NODE_PORT: ${NODE_PORT:-not set}" >&2
  echo "  - Node version: $(node --version)" >&2
  echo "  - Using main file: $MAIN_FILE" >&2

  # Starte den Server (exec ersetzt den Shell-Prozess)
  exec node "$MAIN_FILE"
else
  echo "🔧 Starting in development mode..."
  npx concurrently --kill-others \
    'npx nx run-many -t start -p twenty-server twenty-front' \
    'npx wait-on tcp:3000 && npx nx run twenty-server:worker'
fi
