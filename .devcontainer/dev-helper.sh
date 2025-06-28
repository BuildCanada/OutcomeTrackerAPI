#!/bin/bash

# Simple script to help with common dev container database tasks

case "$1" in
  "reset")
    echo "🔄 Resetting database..."
    rails db:drop db:create db:migrate db:seed
    echo "✅ Database reset complete!"
    ;;
  "migrate")
    echo "🔄 Running migrations..."
    rails db:migrate
    echo "✅ Migrations complete!"
    ;;
  "seed")
    echo "🌱 Seeding database..."
    rails db:seed
    echo "✅ Seeding complete!"
    ;;
  "console")
    echo "🚀 Starting Rails console..."
    rails console
    ;;
  "server")
    echo "🚀 Starting Rails server..."
    rails server -b 0.0.0.0
    ;;
  *)
    echo "Usage: $0 {reset|migrate|seed|console|server}"
    echo ""
    echo "Commands:"
    echo "  reset   - Drop, create, migrate and seed the database"
    echo "  migrate - Run pending migrations"
    echo "  seed    - Seed the database"
    echo "  console - Start Rails console"
    echo "  server  - Start Rails server (bound to all interfaces)"
    exit 1
    ;;
esac
