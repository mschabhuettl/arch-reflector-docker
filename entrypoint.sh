#!/usr/bin/env bash
set -euo pipefail

# EntryPoint Script
#
# Modes:
# - ONE_SHOT=true: Run reflector-update once and exit.
# - ONE_SHOT=false: Run a cron schedule defined by REFLECTOR_SCHEDULE.
#
# Environment Variables:
# - ONE_SHOT: "true" or "false" (default: "false")
# - REFLECTOR_SCHEDULE: A cron schedule (default: "0 * * * *" for hourly)
# - REFLECTOR_ARGS: Custom arguments for reflector, overrides defaults if set.
# - TZ: Timezone, default is UTC. If set, tzdata is installed and this script configures the timezone.
# - LOG_LEVEL: "quiet", "normal", or "debug" (default: "normal" if unset)
#
# Validation:
# - Checks that REFLECTOR_SCHEDULE has 5 fields if ONE_SHOT=false.
#
# Logging:
# - In "quiet" mode: minimal output.
# - In "debug" mode: detailed output including environment variable states.
# - In "normal" mode: standard messages.

ONE_SHOT="${ONE_SHOT:-false}"
REFLECTOR_SCHEDULE="${REFLECTOR_SCHEDULE:-0 * * * *}"
LOG_LEVEL="${LOG_LEVEL:-normal}"

# Function for logging depending on LOG_LEVEL
log() {
    local level="$1"
    shift
    case "$LOG_LEVEL" in
        quiet)
            # Print only errors or critical info if level = error
            [ "$level" = "error" ] && echo "ERROR: $*"
            ;;
        debug)
            # Print everything
            echo "[$level] $*"
            ;;
        normal)
            # Print normal and error, but not debug details
            [ "$level" = "error" ] && echo "ERROR: $*" || ([ "$level" = "normal" ] && echo "$*")
            ;;
        *)
            # If LOG_LEVEL is somehow invalid, fallback to normal
            [ "$level" = "error" ] && echo "ERROR: $*" || ([ "$level" = "normal" ] && echo "$*")
            ;;
    esac
}

# Set timezone if TZ is provided
if [ -n "${TZ:-}" ]; then
    if [ -f "/usr/share/zoneinfo/$TZ" ]; then
        ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
        log normal "Timezone set to $TZ"
    else
        log error "Invalid TZ value '$TZ'. Falling back to UTC."
    fi
fi

# If we are not in ONE_SHOT mode, validate cron schedule
if [ "$ONE_SHOT" = "false" ]; then
    fields=$(echo "$REFLECTOR_SCHEDULE" | awk '{print NF}')
    if [ "$fields" -ne 5 ]; then
        log error "Invalid REFLECTOR_SCHEDULE format: '$REFLECTOR_SCHEDULE'. Must have 5 fields."
        exit 1
    fi
fi

# Debug logging of environment if in debug mode
if [ "$LOG_LEVEL" = "debug" ]; then
    echo "=== Debugging environment ==="
    echo "ONE_SHOT=$ONE_SHOT"
    echo "REFLECTOR_SCHEDULE=$REFLECTOR_SCHEDULE"
    echo "REFLECTOR_ARGS=${REFLECTOR_ARGS:-<default>}"
    echo "TZ=$TZ"
    echo "LOG_LEVEL=$LOG_LEVEL"
    echo "============================="
fi

if [ "$ONE_SHOT" = "true" ]; then
    log normal "Running in one-shot mode. Updating mirrorlist once and then exiting."
    /usr/local/bin/reflector-update.sh
    log normal "One-shot run completed. Exiting container now."
    exit 0
else
    log normal "Running in cron mode with schedule: $REFLECTOR_SCHEDULE"
    # Set up cron job
    echo "$REFLECTOR_SCHEDULE /usr/local/bin/reflector-update.sh" > /etc/crontab_root
    crontab /etc/crontab_root

    log normal "Starting crond in foreground..."
    exec crond -f -d 8
fi
