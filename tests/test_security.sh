#!/usr/bin/env bash
set -euo pipefail

# Test: Security Validation for Arch Reflector Docker Image

# Variables
IMAGE_NAME="mschabhuettl/arch-reflector-docker:latest"
CONTAINER_NAME="arch-reflector-security-test"

# Logging function
log() {
    echo -e "[SECURITY TEST] $*"
}

log "Pulling the latest Docker image..."
docker pull "$IMAGE_NAME"

log "Starting container for security checks..."
docker run --rm --name "$CONTAINER_NAME" -d "$IMAGE_NAME" tail -f /dev/null

# Check 1: Validate sensitive environment variables
log "Checking for sensitive environment variables..."
sensitive_vars=("DOCKER_PASSWORD" "GHCR_TOKEN_ARCH_REFLECTOR_DOCKER")
for var in "${sensitive_vars[@]}"; do
    if docker exec "$CONTAINER_NAME" env | grep -q "$var"; then
        log "FAIL: Sensitive environment variable '$var' is exposed!"
        exit 1
    fi
done
log "PASS: No sensitive environment variables exposed."

# Check 2: File and directory permissions
log "Validating file and directory permissions..."
files_to_check=(
    "/etc/pacman.d/mirrorlist"
    "/var/log/reflector-update.log"
)
expected_perms=("644" "644") # Expected permissions for each file
for i in "${!files_to_check[@]}"; do
    file="${files_to_check[$i]}"
    expected="${expected_perms[$i]}"
    perms=$(docker exec "$CONTAINER_NAME" stat -c '%a' "$file" || echo "missing")
    if [[ "$perms" != "$expected" ]]; then
        log "FAIL: File '$file' has incorrect permissions: $perms (expected $expected)."
        exit 1
    fi
done
log "PASS: All file permissions are secure."

# Check 3: Unused packages
log "Checking for unused packages in the container..."
unused_packages=$(docker exec "$CONTAINER_NAME" pacman -Qdtq || true)
if [[ -n "$unused_packages" ]]; then
    log "FAIL: Unused packages detected: $unused_packages"
    exit 1
fi
log "PASS: No unused packages detected."

# Cleanup
log "Stopping and removing test container..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true

log "Security tests completed successfully!"
exit 0
