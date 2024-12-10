# Start with the latest official Arch Linux image for a rolling-release environment
FROM archlinux:latest

# Ensure no interactive prompts during builds
ENV TERM=xterm-color

# Update base system and install required packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed reflector cronie bash tzdata && \
    pacman -Scc --noconfirm || true

# Optional: Set a default timezone (UTC). User can override with TZ env.
ENV TZ=UTC

# Prepare directories and log files
RUN mkdir -p /usr/local/bin && \
    mkdir -p /var/log && \
    touch /var/log/reflector-update.log

# Copy our custom scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY reflector-update.sh /usr/local/bin/reflector-update.sh

# Ensure scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/reflector-update.sh

# Healthcheck: Ensure cron is running and mirrorlist exists
HEALTHCHECK --interval=30s --timeout=5s CMD pgrep crond && [ -s /etc/pacman.d/mirrorlist ] || exit 1

# Use the entrypoint script to handle all startup logic
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
