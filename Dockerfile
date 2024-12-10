# Start with the latest official Arch Linux image for a rolling-release environment
FROM archlinux:latest

# Set a terminal type for interactive operations and ensure no user prompts halt the build
ENV TERM=xterm-color

# Update the base system and install required packages:
# - reflector: for selecting and ranking Arch Linux mirrors
# - cronie: provides cron for scheduled tasks
# - bash: ensures a proper shell environment
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm reflector cronie bash && \
    pacman -Scc --noconfirm

# Prepare directories and log files:
# /usr/local/bin: place custom scripts here
# /var/log: store logs from reflector updates here
RUN mkdir -p /usr/local/bin && \
    mkdir -p /var/log && \
    touch /var/log/reflector-update.log

# Copy our scripts into the container:
# - entrypoint.sh: decides whether to run once or start cron based on environment variables
# - reflector-update.sh: runs reflector with specified or default parameters
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY reflector-update.sh /usr/local/bin/reflector-update.sh

# Ensure scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/reflector-update.sh

# Set the container entrypoint:
# When the container starts, entrypoint.sh will:
# - Check if ONE_SHOT=true, if so, run reflector-update once and exit
# - Otherwise, set up cron with REFLECTOR_SCHEDULE and run updates periodically
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
