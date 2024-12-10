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
docker run --rm --name "$CONTAINER_NAME" -d \
    -e ONE_SHOT=false \
    -e REFLECTOR_SCHEDULE="*/2 * * * *" \
    "$IMAGE_NAME"

log "Validating container behavior..."

# Check if the mirrorlist is updated
log "Waiting for cron job to execute..."
sleep 150 # Wait 2.5 minutes for the cron job

mirrorlist_updated=$(docker exec "$CONTAINER_NAME" grep -c '^Server' /etc/pacman.d/mirrorlist || echo "0")
if [[ "$mirrorlist_updated" -gt 0 ]]; then
    log "PASS: Cron mode successfully updated the mirrorlist."
else
    log "FAIL: Cron mode did not update the mirrorlist."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    exit 1
fi

# Cleanup
log "Stopping the container after validation..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true

log "Build and run tests completed successfully!"
exit 0
