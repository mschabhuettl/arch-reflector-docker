#!/usr/bin/env bash
set -euo pipefail

# This script updates the Arch Linux mirrorlist using reflector.
# It reads parameters from the environment to allow dynamic customization:
#
# Environment variables:
# - REFLECTOR_ARGS: A string containing reflector parameters.
#   Example: "--country Germany --latest 10 --protocol https --sort rate"
#   If not provided, a default set of parameters will be used.

DEFAULT_ARGS="--latest 10 --sort rate --protocol https"
ARGS="${REFLECTOR_ARGS:-$DEFAULT_ARGS}"

# Run reflector with the specified (or default) arguments to update the mirrorlist
/usr/bin/reflector $ARGS --save /etc/pacman.d/mirrorlist

# Log the update operation with a timestamp in UTC
echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') Mirrorlist updated using args: $ARGS" >> /var/log/reflector-update.log
