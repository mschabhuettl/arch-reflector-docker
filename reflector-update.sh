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

# Run reflector
log debug "Running reflector with args: $ARGS"
/usr/bin/reflector $ARGS

# Count number of mirrors in the generated list
MIRROR_COUNT=$(grep -c '^Server' /etc/pacman.d/mirrorlist || true)

# Log update
TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
echo "$TIMESTAMP Mirrorlist updated using args: $ARGS - Mirrors: $MIRROR_COUNT" >> /var/log/reflector-update.log

log normal "Mirrorlist updated. Mirrors in use: $MIRROR_COUNT"

# Log rotation if > 1MB
LOG_SIZE=$(stat -c%s /var/log/reflector-update.log || echo 0)
MAX_SIZE=$((1024*1024))

if [ "$LOG_SIZE" -gt "$MAX_SIZE" ]; then
    log normal "Log size exceeded 1MB, rotating..."
    mv /var/log/reflector-update.log /var/log/reflector-update.log.1
    touch /var/log/reflector-update.log
    log normal "Log rotated."
fi
