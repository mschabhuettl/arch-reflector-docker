#!/usr/bin/env bash
set -euo pipefail

# This entrypoint script determines how the container will operate based on environment variables.
# It can run either:
# 1. A cron-based schedule (USE_CRON=true), where reflector-update.sh runs at a set interval.
# 2. A simple loop (USE_CRON=false), calling reflector-update.sh periodically after sleeping.

# Environment variables:
# - USE_CRON:          "true" or "false" (default "false"), whether to use cron scheduling or not.
# - REFLECTOR_SCHEDULE: A cron schedule string (e.g., "0 * * * *") if USE_CRON=true.
#                       Default: "0 * * * *" (once per hour).
# - REFLECTOR_ARGS:     Arguments passed directly to reflector.
# - REFLECTOR_INTERVAL: Interval in seconds for the loop mode if USE_CRON=false. Default: 3600 (1 hour).

CRON_SCHEDULE="${REFLECTOR_SCHEDULE:-0 * * * *}"
INTERVAL="${REFLECTOR_INTERVAL:-3600}"
USE_CRON="${USE_CRON:-false}"

echo "=== arch-reflector-docker configuration ==="
echo "  USE_CRON = $USE_CRON"
if [ "$USE_CRON" = "true" ]; then
    echo "  Using cron schedule: $CRON_SCHEDULE"
else
    echo "  Using loop interval: $INTERVAL seconds"
fi
echo "  Reflector arguments: ${REFLECTOR_ARGS:-<none provided>}"
echo "==========================================="

# If cron-based scheduling is requested:
if [ "$USE_CRON" = "true" ]; then
    # Dynamically generate a crontab entry that calls reflector-update.sh at the specified schedule.
    echo "$CRON_SCHEDULE /usr/local/bin/reflector-update.sh" > /etc/crontab_root
    crontab /etc/crontab_root
    
    # Run crond in the foreground so the container doesn't exit.
    exec crond -f -d 8
else
    # If not using cron, run in a loop:
    # 1. Call reflector-update.sh
    # 2. Sleep for INTERVAL seconds
    # 3. Repeat indefinitely
    while true; do
        /usr/local/bin/reflector-update.sh
        sleep "$INTERVAL"
    done
fi
