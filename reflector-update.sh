#!/usr/bin/env bash
set -euo pipefail

# This script updates the Arch Linux mirrorlist using reflector.
# Default arguments (if REFLECTOR_ARGS not set):
# --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5
#
# If REFLECTOR_ARGS is set, it will override the default arguments entirely.
#
# Logging:
# After each update, the script logs the timestamp and arguments used
# to /var/log/reflector-update.log (in UTC).

DEFAULT_ARGS="--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5"
ARGS="${REFLECTOR_ARGS:-$DEFAULT_ARGS}"

/usr/bin/reflector $ARGS

echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') Mirrorlist updated using args: $ARGS" >> /var/log/reflector-update.log
