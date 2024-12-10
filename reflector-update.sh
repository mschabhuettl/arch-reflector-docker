#!/usr/bin/env bash
set -euo pipefail

# Reflector Update Script
#
# This script updates the Arch Linux mirrorlist using reflector.
# Default arguments (if REFLECTOR_ARGS not set):
#   --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5
#
# LOG_LEVEL influences how much output is printed:
# - quiet: minimal
# - normal: standard messages
# - debug: detailed output

LOG_LEVEL="${LOG_LEVEL:-normal}"

# Log file for updates
LOG_FILE="/var/log/reflector-update.log"
DEBUG_LOG="/tmp/reflector-debug.log"

# Enable debugging and log output to a debug file
set -x
exec >> "$DEBUG_LOG" 2>&1

# Logging function
log() {
    local level="$1"
    shift
    if [[ "$LOG_LEVEL" == "debug" || ( "$LOG_LEVEL" == "normal" && "$level" != "debug" ) || "$level" == "error" ]]; then
        echo "[$level] $*"
    fi
}

DEFAULT_ARGS="--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5"
ARGS="${REFLECTOR_ARGS:-$DEFAULT_ARGS}"

# Ensure log file exists
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
fi

log debug "Starting Reflector Update Script"
log debug "Arguments for reflector: $ARGS"

# Run reflector
if /usr/bin/reflector $ARGS; then
    log normal "Reflector executed successfully."
else
    log error "Reflector execution failed!"
    exit 1
fi

# Count number of mirrors in the generated list
if [ -f /etc/pacman.d/mirrorlist ]; then
    MIRROR_COUNT=$(grep -c '^Server' /etc/pacman.d/mirrorlist || true)
else
    log error "Mirrorlist file not found!"
    exit 1
fi

# Log update
TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
echo "$TIMESTAMP Mirrorlist updated using args: $ARGS - Mirrors: $MIRROR_COUNT" >> "$LOG_FILE"

log normal "Mirrorlist updated. Mirrors in use: $MIRROR_COUNT"

# Log rotation if > 1MB
LOG_SIZE=$(stat -c%s "$LOG_FILE" || echo 0)
MAX_SIZE=$((1024*1024))

if [ "$LOG_SIZE" -gt "$MAX_SIZE" ]; then
    log normal "Log size exceeded 1MB, rotating..."
    mv "$LOG_FILE" "$LOG_FILE.1"
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    log normal "Log rotated."
fi
