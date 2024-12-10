# Start with the latest official Arch Linux image to ensure a rolling-release environment
FROM archlinux:latest

# Set a terminal type for any interactive operations; ensures no prompts block installs
ENV TERM=xterm-color

# Update the base system and install required packages:
# - reflector: for selecting and ranking Arch Linux mirrors
# - cronie: for optional scheduled tasks (if the user chooses to use cron)
# - bash: provides a more standard shell environment
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm reflector cronie bash && \
    pacman -Scc --noconfirm

# Prepare directories and log files for our scripts:
# /usr/local/bin: where we place custom scripts
# /var/log: for storing logs from reflector updates
RUN mkdir -p /usr/local/bin && \
    mkdir -p /var/log && \
    touch /var/log/reflector-update.log

# Copy our custom scripts into the container:
# entrypoint.sh: determines how updates run (cron or loop) based on ENV variables
# reflector-update.sh: runs reflector with parameters specified via ENV variables
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY reflector-update.sh /usr/local/bin/reflector-update.sh

# Ensure the scripts are executable so the container can run them
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/reflector-update.sh

# Set the container entrypoint to our entrypoint script:
# When the container starts, entrypoint.sh will:
# - Check environment variables (e.g., USE_CRON, REFLECTOR_INTERVAL, REFLECTOR_ARGS)
# - Decide whether to run reflector on a schedule (via cron) or in a timed loop
# - Launch the chosen mechanism to periodically update and optimize the mirrorlist
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
