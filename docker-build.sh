#!/usr/bin/env bash
#
# build.sh - Linux/macOS Build Script
#
# This script automates the process of building and running the Docker container
# with version information dynamically injected at build time.

set -euo pipefail

if [[ "${1:-}" != "" ]]; then
  echo "Error: unknown option '${1}'."
  echo "Usage: ./docker-build.sh"
  exit 1
fi

# --- Step 1: Choose Environment ---
echo "Please select an option:"
echo "1) Run using Pre-built Image (Recommended)"
echo "2) Build from Source and Run (For Developers)"
read -r -p "Enter choice [1-2]: " choice

# --- Step 2: Execute based on choice ---
case "$choice" in
  1)
    echo "--- Running with Pre-built Image ---"
    docker compose up -d --remove-orphans --no-build
    echo "Services are starting from remote image."
    echo "Run 'docker compose logs -f' to see the logs."
    ;;
  2)
    echo "--- Building from Source and Running ---"

    # Get Version Information
    VERSION="$(git describe --tags --always --dirty)"
    COMMIT="$(git rev-parse --short HEAD)"
    BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    echo "Building with the following info:"
    echo "  Version: ${VERSION}"
    echo "  Commit: ${COMMIT}"
    echo "  Build Date: ${BUILD_DATE}"
    echo "----------------------------------------"

    export VERSION COMMIT BUILD_DATE
    export CLI_PROXY_IMAGE="${CLI_PROXY_IMAGE:-cli-proxy-api}"
    export CLI_PROXY_IMAGE_TAG="${CLI_PROXY_IMAGE_TAG:-local}"
    export CLI_PROXY_PULL_POLICY="${CLI_PROXY_PULL_POLICY:-build}"
    export CLI_PROXY_CONTAINER_NAME="${CLI_PROXY_CONTAINER_NAME:-cli-proxy-api-dev}"

    echo "Building the Docker image..."
    docker compose -f docker-compose.dev.yml build \
      --build-arg VERSION="${VERSION}" \
      --build-arg COMMIT="${COMMIT}" \
      --build-arg BUILD_DATE="${BUILD_DATE}"

    echo "Starting the services..."
    docker compose -f docker-compose.dev.yml up -d --remove-orphans --pull never

    echo "Build complete. Services are starting."
    echo "Run 'docker compose -f docker-compose.dev.yml logs -f' to see the logs."
    ;;
  *)
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
    ;;
esac
