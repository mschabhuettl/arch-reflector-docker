# Start with the latest official Arch Linux image for a rolling-release environment
FROM archlinux:latest

# Set environment variables for non-interactive installation
ENV TERM=xterm-color
ENV TZ=UTC

# Update system and install necessary packages in a single layer
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed reflector cronie bash tzdata && \
    pacman -Scc --noconfirm && \
    mkdir -p /usr/local/bin /var/log && \
    touch /var/log/reflector-update.log

# Copy custom scripts to the appropriate location
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY reflector-update.sh /usr/local/bin/reflector-update.sh

# Ensure scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/reflector-update.sh

# Healthcheck to ensure cron is running and the mirrorlist is valid
HEALTHCHECK --interval=30s --timeout=5s \
    CMD pgrep crond && [ -s /etc/pacman.d/mirrorlist ] || exit 1

# Use the entrypoint script for startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
