#!/usr/bin/env bash
set -euo pipefail

# Test: Build and Run Validation for Arch Reflector Docker Image

# Variables
IMAGE_NAME="mschabhuettl/arch-reflector-docker:test"
CONTAINER_NAME="arch-reflector-build-test"
DOCKERFILE="Dockerfile"

# Logging function
log() {
    echo -e "[BUILD & RUN TEST] $*"
}

log "Starting the build process for the Docker image..."
if docker build -f "$DOCKERFILE" -t "$IMAGE_NAME" .; then
    log "PASS: Docker image built successfully."
else
    log "FAIL: Docker image build failed."
    exit 1
fi

log "Running the built Docker image..."
if docker run --rm --name "$CONTAINER_NAME" "$IMAGE_NAME" /bin/bash -c "echo Test Run"; then
    log "PASS: Docker container started and executed successfully."
else
    log "FAIL: Docker container run failed."
    exit 1
fi

log "Performing additional runtime validations..."

# Check 1: Verify if reflector is installed
log "Checking if 'reflector' is installed in the container..."
if docker run --rm "$IMAGE_NAME" /usr/bin/reflector --version >/dev/null 2>&1; then
    log "PASS: 'reflector' is installed."
else
    log "FAIL: 'reflector' is not installed."
    exit 1
fi

# Check 2: Verify healthcheck behavior
log "Checking container health status..."
docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" tail -f /dev/null
sleep 5
if docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' | grep -q "healthy"; then
    log "PASS: Container healthcheck passed."
else
    log "FAIL: Container healthcheck failed."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    exit 1
fi

# Cleanup
log "Stopping and cleaning up the test container..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rmi "$IMAGE_NAME" >/dev/null 2>&1 || true

log "Build and run tests completed successfully!"
exit 0
