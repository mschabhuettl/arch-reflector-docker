# Start with the latest official Arch Linux image for a rolling-release environment
FROM archlinux:latest

# Ensure no interactive prompts during builds
ENV TERM=xterm-color

# Update base system, install reflector, cron (cronie), bash, and tzdata for timezones
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm reflector cronie bash tzdata && \
    pacman -Scc --noconfirm

# Optional: Set a default timezone (UTC). User can override with TZ env.
ENV TZ=UTC

# Prepare directories and log files:
# /usr/local/bin: for custom scripts
# /var/log: for storing logs
RUN mkdir -p /usr/local/bin && \
    mkdir -p /var/log && \
    touch /var/log/reflector-update.log

# Copy our scripts:
# entrypoint.sh: controls one-shot vs. cron mode, validates schedule, sets up environment
# reflector-update.sh: runs reflector with given or default parameters and logs results, rotates logs
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY reflector-update.sh /usr/local/bin/reflector-update.sh

# Make sure scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/reflector-update.sh

# Set a HEALTHCHECK:
# Check that the mirrorlist is non-empty and that crond is running (in non-oneshot mode).
# If ONE_SHOT=true, container will exit after one update anyway, so healthcheck won't matter.
HEALTHCHECK --interval=5m --timeout=10s CMD \
    sh -c '[ "${ONE_SHOT:-false}" = "true" ] || ( [ -s /etc/pacman.d/mirrorlist ] && pgrep crond > /dev/null )'

# Use entrypoint.sh to handle all startup logic
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
