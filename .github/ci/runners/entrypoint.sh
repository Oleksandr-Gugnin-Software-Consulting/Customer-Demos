#!/bin/bash
set -e

# Wait for required environment variables
if [ -z "$RUNNER_NAME" ]; then
    echo "❌ RUNNER_NAME is not set"
    exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
    echo "❌ RUNNER_TOKEN is not set"
    exit 1
fi

if [ -z "$REPO_URL" ]; then
    echo "❌ REPO_URL is not set"
    exit 1
fi

# Configure runner
if [ ! -f .runner ]; then
    echo "🔧 Configuring GitHub Actions runner..."
    ./config.sh \
        --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$LABELS" \
        --work "$RUNNER_WORKDIR" \
        --unattended \
        --replace
fi

# Cleanup function
cleanup() {
    echo "🛑 Removing runner..."
    ./config.sh remove --token "$RUNNER_TOKEN"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start runner
echo "🚀 Starting GitHub Actions runner: $RUNNER_NAME"
./run.sh & wait $!
