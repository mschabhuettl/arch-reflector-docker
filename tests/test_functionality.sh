#!/usr/bin/env bash
set -euo pipefail

# Test: Functionality Validation for Arch Reflector Docker Image

# Variables
IMAGE_NAME="mschabhuettl/arch-reflector-docker:latest"
CONTAINER_NAME="arch-reflector-functionality-test"

# Logging function
log() {
    echo -e "[FUNCTIONALITY TEST] $*"
}

log "Pulling the latest Docker image..."
docker pull "$IMAGE_NAME"

# Test 1: ONE_SHOT Mode
log "Testing ONE_SHOT mode..."
docker run --rm \
    -e ONE_SHOT=true \
    -v mirrorlist-test:/etc/pacman.d \
    "$IMAGE_NAME"
if [[ "$(docker volume inspect mirrorlist-test | grep -c 'mirrorlist')" -gt 0 ]]; then
    log "PASS: ONE_SHOT mode successfully updated the mirrorlist."
else
    log "FAIL: ONE_SHOT mode did not update the mirrorlist."
    exit 1
fi

# Test 2: Cron Mode
log "Testing Cron mode..."
docker run --rm --name "$CONTAINER_NAME" -d \
    -e ONE_SHOT=false \
    -e REFLECTOR_SCHEDULE="*/2 * * * *" \
    -v mirrorlist-test:/etc/pacman.d \
    "$IMAGE_NAME"

log "Waiting for cron job to execute..."
sleep 150

mirrorlist_updated=$(docker exec "$CONTAINER_NAME" grep -c '^Server' /etc/pacman.d/mirrorlist || echo "0")
if [[ "$mirrorlist_updated" -gt 0 ]]; then
    log "PASS: Cron mode successfully updated the mirrorlist."
else
    log "FAIL: Cron mode did not update the mirrorlist."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    exit 1
fi

# Cleanup
log "Stopping test container and cleaning up resources..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker volume rm mirrorlist-test >/dev/null 2>&1 || true

log "Functionality tests completed successfully!"
exit 0
