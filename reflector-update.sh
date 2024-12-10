#!/usr/bin/env bash
set -euo pipefail

# Reflector Update Script
#
# This script updates the Arch Linux mirrorlist using reflector.
# Default arguments (if REFLECTOR_ARGS not set):
#   --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5
#
# After updating the mirrorlist, it logs a timestamped message with the number of mirrors chosen.
# Also, checks the log file size and rotates if > 1MB.
#
# LOG_LEVEL influences how much output is printed:
# - quiet: minimal
# - normal: standard messages
# - debug: detailed output

LOG_LEVEL="${LOG_LEVEL:-normal}"

# Log file
LOG_FILE="/var/log/reflector-update.log"

# Logging function respecting LOG_LEVEL
log() {
    local level="$1"
    shift
    case "$LOG_LEVEL" in
        quiet)
            [ "$level" = "error" ] && echo "ERROR: $*"
            ;;
        debug)
            echo "[$level] $*"
            ;;
        normal)
            [ "$level" = "error" ] && echo "ERROR: $*" || ([ "$level" = "normal" ] && echo "$*")
            ;;
        *)
            [ "$level" = "error" ] && echo "ERROR: $*" || ([ "$level" = "normal" ] && echo "$*")
            ;;
    esac
}

DEFAULT_ARGS="--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5"
ARGS="${REFLECTOR_ARGS:-$DEFAULT_ARGS}"

# Ensure log file exists
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
fi

# Run reflector
log debug "Executing reflector command with args: $ARGS"
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
