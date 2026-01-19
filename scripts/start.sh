#!/bin/sh
set -e

# Prüfe, ob wir in Production/Railway sind
if [ "$NODE_ENV" = "production" ] || [ -n "$RAILWAY_ENVIRONMENT_ID" ]; then
  echo "🚀 Starting in production mode..."
  # Stelle sicher, dass wir im Root-Verzeichnis sind
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  cd "$PROJECT_ROOT/packages/twenty-server"

  # Prüfe, ob das Frontend-Verzeichnis existiert
  if [ ! -d "dist/front" ]; then
    echo "⚠️  Warning: Frontend directory not found at dist/front"
    echo "📁 Current directory: $(pwd)"
    echo "📁 Contents of dist:"
    ls -la dist/ || echo "dist directory does not exist"
  else
    echo "✅ Frontend directory found at dist/front"
  fi

  node dist/main
else
  echo "🔧 Starting in development mode..."
  npx concurrently --kill-others \
    'npx nx run-many -t start -p twenty-server twenty-front' \
    'npx wait-on tcp:3000 && npx nx run twenty-server:worker'
fi
