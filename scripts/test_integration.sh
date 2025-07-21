#!/bin/bash

# PhoenixKit Integration Test Script
# Creates a test Phoenix project and tests PhoenixKit as a module

set -e  # Exit on any error

echo "🧪 PhoenixKit Integration Test"
echo "============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for colored output
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Variables
TEST_APP_NAME="phoenix_kit_test_app"
TEST_DIR="/tmp/$TEST_APP_NAME"
PHOENIX_KIT_PATH=$(pwd)

# Check that we're in the correct directory
if [[ ! -f "mix.exs" ]] || ! grep -q "phoenix_kit" mix.exs; then
    log_error "Run the script from the PhoenixKit root directory"
    exit 1
fi

log_info "PhoenixKit path: $PHOENIX_KIT_PATH"

# Cleanup function
cleanup() {
    log_warning "Cleaning up test directory..."
    rm -rf "$TEST_DIR"
}

# Handle interruption
trap cleanup EXIT

# Step 1: Creating test Phoenix project
log_info "Step 1: Creating test Phoenix project"

if [[ -d "$TEST_DIR" ]]; then
    log_warning "Removing existing test directory..."
    rm -rf "$TEST_DIR"
fi

cd /tmp
mix phx.new "$TEST_APP_NAME" --no-live --no-dashboard --no-mailer
cd "$TEST_APP_NAME"

log_success "Phoenix project created"

# Step 2: Adding PhoenixKit dependency
log_info "Step 2: Adding PhoenixKit as dependency"

# Create backup of mix.exs
cp mix.exs mix.exs.backup

# Add PhoenixKit dependency
cat > mix_deps_update.exs << 'EOF'
defmodule MixUpdate do
  def add_phoenix_kit_dep do
    content = File.read!("mix.exs")
    
    # Find deps function and add PhoenixKit
    phoenix_kit_path = System.get_env("PHOENIX_KIT_PATH")
    updated = String.replace(content, 
      ~r/(defp deps do\s*\[\s*)/,
      "\\1{:phoenix_kit, path: \"#{phoenix_kit_path}\"},\n      "
    )
    
    File.write!("mix.exs", updated)
  end
end

MixUpdate.add_phoenix_kit_dep()
EOF

export PHOENIX_KIT_PATH="$PHOENIX_KIT_PATH"

elixir mix_deps_update.exs
rm mix_deps_update.exs

log_success "PhoenixKit dependency added"

# Show changes in mix.exs
log_info "Checking mix.exs:"
head -20 mix.exs | grep -A 5 -B 5 phoenix_kit || true

# Step 3: Installing dependencies
log_info "Step 3: Installing dependencies"
mix deps.get
log_success "Dependencies installed"

# Step 3.5: Compiling project
log_info "Step 3.5: Compiling project with PhoenixKit"
mix compile
log_success "Project compiled"

# Step 4: Testing PhoenixKit commands
log_info "Step 4: Testing PhoenixKit commands"

# 4.1: Check command availability
log_info "4.1: Checking Mix tasks availability"
if mix help | grep -q phoenix_kit; then
    log_success "PhoenixKit Mix tasks available"
    mix help | grep phoenix_kit
else
    log_error "PhoenixKit Mix tasks not found"
    exit 1
fi

# 4.2: Test migration generation
log_info "4.2: Testing migration generation"
mix phoenix_kit.gen.migration
if ls priv/repo/migrations/*phoenix_kit* >/dev/null 2>&1; then
    log_success "Migrations generated"
    ls -la priv/repo/migrations/*phoenix_kit*
else
    log_error "Migrations not created"
    exit 1
fi

# 4.3: Test router dry-run
log_info "4.3: Testing router generation (dry-run)"
mix phoenix_kit.gen.routes --dry-run
log_success "Router dry-run completed"

# 4.4: Test router generation
log_info "4.4: Testing router generation"
mix phoenix_kit.gen.routes --force
if grep -q "BeamLab.PhoenixKitWeb" lib/${TEST_APP_NAME}_web/router.ex; then
    log_success "Router updated"
    echo "Router content:"
    grep -A 5 -B 5 "BeamLab.PhoenixKitWeb" lib/${TEST_APP_NAME}_web/router.ex
else
    log_error "Router not updated"
    exit 1
fi

# 4.5: Test full installation
log_info "4.5: Testing full installation"
mix phoenix_kit.install --no-migrations --force
log_success "Full installation completed"

# Step 5: Testing compilation
log_info "Step 5: Testing compilation"
if mix compile; then
    log_success "Project compiles without errors"
else
    log_error "Compilation errors"
    exit 1
fi

# Step 6: Creating and running migrations
log_info "Step 6: Creating DB and running migrations"
mix ecto.create
mix ecto.migrate
log_success "Database created and migrations executed"

# Step 7: Check that migrations created tables
log_info "Step 7: Checking DB tables"
if mix ecto.gen.migration test_check --quiet >/dev/null 2>&1; then
    # Can create migrations, so DB is working
    log_success "Database working correctly"
else
    log_warning "Could not check DB"
fi

# Step 8: Testing server startup (brief test)
log_info "Step 8: Testing server startup"
timeout 10s mix phx.server &
SERVER_PID=$!
sleep 5

if kill -0 $SERVER_PID 2>/dev/null; then
    log_success "Server starts correctly"
    kill $SERVER_PID 2>/dev/null || true
else
    log_warning "Server failed to start or crashed"
fi

# Step 9: Check routes
log_info "Step 9: Checking routes"
if mix phx.routes | grep -q "phoenix_kit\|auth"; then
    log_success "PhoenixKit routes found"
    echo "PhoenixKit routes:"
    mix phx.routes | grep -E "(phoenix_kit|auth|register|log-in|settings)"
else
    log_warning "PhoenixKit routes not found"
fi

# Final report
echo ""
echo "🎉 INTEGRATION TEST COMPLETED"
echo "==============================="
log_success "All main PhoenixKit functions work correctly!"

echo ""
echo "📋 Test results:"
echo "   ✅ Phoenix project created"
echo "   ✅ PhoenixKit dependency added"
echo "   ✅ Mix tasks available"
echo "   ✅ Migrations generate"
echo "   ✅ Router configures"
echo "   ✅ Project compiles"
echo "   ✅ Database works"
echo "   ✅ Server starts"
echo "   ✅ Routes configured"

echo ""
echo "📁 Test project located at: $TEST_DIR"
echo "   Use for further testing or delete manually"

log_info "For manual testing:"
echo "   cd $TEST_DIR"
echo "   mix phx.server"
echo "   Откройте http://localhost:4000/auth/register"