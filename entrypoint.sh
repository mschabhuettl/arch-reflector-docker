#!/usr/bin/env bash
set -euo pipefail

# This entrypoint script controls how the container updates the Arch Linux mirrorlist.
#
# Two modes:
# 1. ONE_SHOT=true: Update the mirrorlist once using reflector-update.sh and then exit.
# 2. ONE_SHOT=false (default) or unset: Set up a cron job to periodically run reflector-update.sh.
#
# Environment variables:
# - ONE_SHOT: "true" or "false" (default: "false")
#   If "true", the container updates once and exits immediately.
#   If "false", the container will run a cron-based schedule.
#
# - REFLECTOR_SCHEDULE: A cron schedule string, e.g. "0 * * * *"
#   Default: "0 * * * *" (once every hour) if ONE_SHOT=false.
#
# - REFLECTOR_ARGS: Additional arguments for reflector, overriding defaults.
#   Default arguments (if not set):
#   --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5
#
# Logs and outputs:
# - Reflector updates are logged to /var/log/reflector-update.log
#
# Cron notes:
# - If using cron, this container will remain running, with crond in the foreground.

ONE_SHOT="${ONE_SHOT:-false}"
CRON_SCHEDULE="${REFLECTOR_SCHEDULE:-0 * * * *}"

echo "=== arch-reflector-docker configuration ==="
echo "  ONE_SHOT = $ONE_SHOT"
if [ "$ONE_SHOT" = "true" ]; then
    echo "  Running once, no cron scheduling."
else
    echo "  Running with cron schedule: $CRON_SCHEDULE"
fi
echo "  Reflector arguments: ${REFLECTOR_ARGS:-<default>}"
echo "==========================================="

if [ "$ONE_SHOT" = "true" ]; then
    # Just run reflector-update once and exit.
    /usr/local/bin/reflector-update.sh
    echo "One-shot run completed. Exiting container."
    exit 0
else
    # Set up a cron job for periodic updates
    echo "$CRON_SCHEDULE /usr/local/bin/reflector-update.sh" > /etc/crontab_root
    crontab /etc/crontab_root

    # Run cron in the foreground to keep the container alive
    exec crond -f -d 8
fi
