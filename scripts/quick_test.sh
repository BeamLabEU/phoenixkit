#!/bin/bash

# Quick PhoenixKit Test Script
# Simple PhoenixKit testing in a new Phoenix project

set -e

echo "🚀 Quick PhoenixKit Test"
echo "======================"

# Variables
TEST_APP="test_phoenix_kit_$(date +%s)"
PHOENIX_KIT_PATH=$(pwd)

# Check
if [[ ! -f "mix.exs" ]] || ! grep -q "phoenix_kit" mix.exs; then
    echo "❌ Run from PhoenixKit root directory"
    exit 1
fi

echo "📁 Creating test project: $TEST_APP"

# Create project
cd /tmp
mix phx.new "$TEST_APP" --no-live --no-dashboard --no-mailer

cd "$TEST_APP"

echo "📦 Adding PhoenixKit dependency..."

# Simple dependency addition
sed -i.bak 's|def deps do|def deps do\
      {:phoenix_kit, path: "'$PHOENIX_KIT_PATH'"},|' mix.exs

echo "⬇️  Getting dependencies..."
mix deps.get

echo "🔨 Compiling project..."
mix compile

echo "🧪 Testing PhoenixKit commands..."

# Test commands
echo "Testing mix phoenix_kit.gen.migration..."
mix phoenix_kit.gen.migration

echo "Testing mix phoenix_kit.gen.routes --dry-run..."
mix phoenix_kit.gen.routes --dry-run

echo "Testing mix phoenix_kit.install..."
mix phoenix_kit.install --force

echo "🔨 Testing compilation..."
mix compile

echo "🗄️  Testing database..."
mix ecto.create
mix ecto.migrate

echo ""
echo "✅ QUICK TEST PASSED!"
echo ""
echo "Test project created at: /tmp/$TEST_APP"
echo "To manually test:"
echo "  cd /tmp/$TEST_APP"
echo "  mix phx.server"
echo "  Open: http://localhost:4000/auth/register"
echo ""
echo "To cleanup:"
echo "  rm -rf /tmp/$TEST_APP"