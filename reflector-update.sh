#!/usr/bin/env bash
set -euo pipefail

# Reflector Update Script
#
# This script updates the Arch Linux mirrorlist using reflector.
#
# Environment Variables:
# - LOG_LEVEL: "quiet", "normal", or "debug" (default: "normal")
# - REFLECTOR_ARGS: Custom arguments for reflector
#
# Default Arguments:
# --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5

LOG_LEVEL="${LOG_LEVEL:-normal}"
LOG_FILE="/var/log/reflector-update.log"
DEFAULT_ARGS="--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5"
ARGS="${REFLECTOR_ARGS:-$DEFAULT_ARGS}"
MAX_LOG_SIZE=$((1024 * 1024)) # 1MB

# Function: Logging
log() {
    local level="$1"
    shift
    if [[ "$LOG_LEVEL" == "debug" || ("$LOG_LEVEL" == "normal" && "$level" != "debug") || "$level" == "error" ]]; then
        echo "[$level] $*"
    fi
}

# Ensure log file exists
prepare_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 666 "$LOG_FILE"
    fi
}

# Rotate log file if it exceeds the size limit
rotate_logs() {
    local size
    size=$(stat -c%s "$LOG_FILE" || echo 0)
    if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
        log normal "Log file exceeded 1MB, rotating..."
        mv "$LOG_FILE" "${LOG_FILE}.1"
        touch "$LOG_FILE"
        chmod 666 "$LOG_FILE"
        log normal "Log file rotated."
    fi
}

# Update mirrorlist using reflector
update_mirrorlist() {
    log debug "Executing reflector with arguments: $ARGS"
    if /usr/bin/reflector $ARGS; then
        log normal "Reflector executed successfully."
    else
        log error "Reflector execution failed!"
        exit 1
    fi
}

# Count mirrors and log results
count_mirrors() {
    if [ -f /etc/pacman.d/mirrorlist ]; then
        local count
        count=$(grep -c '^Server' /etc/pacman.d/mirrorlist || true)
        local timestamp
        timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
        echo "$timestamp Mirrorlist updated using args: $ARGS - Mirrors: $count" >> "$LOG_FILE"
        log normal "Mirrorlist updated. Mirrors in use: $count"
    else
        log error "Mirrorlist file not found!"
        exit 1
    fi
}

# Main logic
prepare_log_file
rotate_logs
update_mirrorlist
count_mirrors
rotate_logs
