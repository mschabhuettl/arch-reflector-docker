#!/usr/bin/env bash
set -euo pipefail

# EntryPoint Script
#
# Modes:
# - ONE_SHOT=true: Run reflector-update once and exit.
# - ONE_SHOT=false: Use crontab for periodic updates.
#
# Environment Variables:
# - ONE_SHOT: "true" or "false" (default: "false")
# - REFLECTOR_SCHEDULE: A cron schedule string, e.g., "0 * * * *" (default: "0 * * * *" for hourly updates)
# - REFLECTOR_ARGS: Custom arguments for reflector
# - TZ: Timezone, e.g., "Europe/Vienna" (default: UTC)
# - LOG_LEVEL: "quiet", "normal", or "debug" (default: "normal")
#

ONE_SHOT="${ONE_SHOT:-false}"
REFLECTOR_SCHEDULE="${REFLECTOR_SCHEDULE:-0 * * * *}"
LOG_LEVEL="${LOG_LEVEL:-normal}"

# Function for logging based on LOG_LEVEL
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

# Set timezone if provided
if [ -n "${TZ:-}" ]; then
    if [ -f "/usr/share/zoneinfo/$TZ" ]; then
        ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
        log normal "Timezone set to $TZ"
    else
        log error "Invalid TZ value '$TZ'. Falling back to UTC."
    fi
fi

# Validate cron schedule if not in one-shot mode
if [ "$ONE_SHOT" = "false" ]; then
    fields=$(echo "$REFLECTOR_SCHEDULE" | awk '{print NF}')
    if [ "$fields" -ne 5 ]; then
        log error "Invalid REFLECTOR_SCHEDULE format: '$REFLECTOR_SCHEDULE'. Must have 5 fields."
        exit 1
    fi
fi

if [ "$ONE_SHOT" = "true" ]; then
    log normal "Running in one-shot mode. Updating mirrorlist once and then exiting."
    /usr/local/bin/reflector-update.sh
    log normal "One-shot run completed. Exiting container now."
    exit 0
else
    log normal "Running in cron mode with schedule: $REFLECTOR_SCHEDULE"

    # Ensure the required cache directory exists
    mkdir -p /root/.cache/crontab

    # Ensure the log directory and file exist
    mkdir -p /var/log
    touch /var/log/reflector-update.log
    chmod 666 /var/log/reflector-update.log

    # Create a crontab entry
    echo "$REFLECTOR_SCHEDULE /usr/local/bin/reflector-update.sh >> /var/log/reflector-update.log 2>&1" | crontab -
    
    # Validate that the crontab was set correctly
    if ! crontab -l | grep -q "/usr/local/bin/reflector-update.sh"; then
        log error "Failed to set crontab entry!"
        exit 1
    fi

    # Start the cron daemon in foreground mode
    log normal "Starting cron daemon..."
    exec crond -f
fi
