# 📦 **Arch Reflector Docker Image**

Welcome to the **Arch Reflector Docker** repository! This project provides a Docker image to easily update and optimize Arch Linux mirrorlists using `reflector`. 🐳✨  
With periodic (cron-based) updates or a one-shot mode, this container ensures your Arch Linux environment always uses the fastest and most reliable mirrors. 🚀🔧

---

## ✨ **Features**
- 🐳 **Dockerized Deployment**: Quickly run Arch Reflector in a portable container.
- ⏱️ **Automated Scheduling**: Use cron to periodically update your mirrorlist.
- 🎯 **One-Shot Mode**: Run once to update mirrors and then exit.
- ⚙️ **Fully Configurable**: Customize reflector parameters via environment variables.
- 🌍 **Timezone Support**: Adjust logs and scheduling to your local time.
- 📜 **Logging & Rotation**: Detailed logging of updates, plus optional log rotation.
- 🔒 **Persistent Storage**: Keep your generated mirrorlist in a Docker volume to ensure updates persist across container restarts.
- 💻 **Simple Integration**: Easily integrate into any CI/CD workflow or system maintenance routine.

---

## 🚀 **Getting Started**

### 🏗️ **Option 1: Using the Prebuilt Image**
For a quick start, use the prebuilt image from Docker Hub:

#### 1️⃣ **Pull the Image**
```bash
docker pull mschabhuettl/arch-reflector-docker:latest
```

#### 2️⃣ **Run the Container with Cron Updates**
```bash
docker run -d 
  --name arch-reflector 
  -e ONE_SHOT=false 
  -e REFLECTOR_SCHEDULE="0 * * * *" 
  -v mirrorlist:/etc/pacman.d 
  mschabhuettl/arch-reflector-docker:latest
```
This runs the container in cron mode, updating your mirrorlist every hour.

#### 3️⃣ **Check Logs**
```bash
docker logs arch-reflector
```
You’ll see the timestamps and parameters used for each update.

---

### 🛠️ **Option 2: Using Docker Compose**

If you prefer `docker compose`, you can set up a `docker-compose.yml` like this:

```yaml
services:
  arch-reflector:
    image: mschabhuettl/arch-reflector-docker:latest
    container_name: arch-reflector
    environment:
      # ONE_SHOT=true: update once and exit
      # ONE_SHOT=false: run cron schedule (default)
      - ONE_SHOT=false

      # Change schedule if desired, default: "0 * * * *" (every hour)
      - REFLECTOR_SCHEDULE=0 * * * *

      # Default Reflector arguments (if REFLECTOR_ARGS not set):
      # --save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5
      # Uncomment and adjust if needed:
      # - REFLECTOR_ARGS=--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5

      # Set TZ to Europe/Vienna for local time (default is UTC):
      # - TZ=Europe/Vienna

      # LOG_LEVEL can be quiet, normal, or debug. Default is normal if unset.
      - LOG_LEVEL=normal
    volumes:
      # Persist mirrorlist so it survives container restarts
      - mirrorlist:/etc/pacman.d
    restart: always

volumes:
  mirrorlist:
```

Then run:
```bash
docker compose up -d
```

---

### 🔄 **One-Shot Mode**

If you only want to update your mirrorlist once and then exit:
```bash
docker run --rm 
  -e ONE_SHOT=true 
  -v mirrorlist:/etc/pacman.d 
  mschabhuettl/arch-reflector-docker:latest
```
This will run reflector once and then the container stops.

---

## ⚙️ **Configuration**

### Environment Variables

| Variable             | Description                                                      | Default                                                                                |
|----------------------|------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| `ONE_SHOT`           | "true": update once and exit, "false": use cron for scheduling   | `false`                                                                                |
| `REFLECTOR_SCHEDULE` | Cron schedule string (5 fields), e.g. "0 * * * *"                | "0 * * * *" (hourly)                                                                   |
| `REFLECTOR_ARGS`     | Custom reflector parameters to override defaults                 | `--save /etc/pacman.d/mirrorlist --country France,Germany --protocol https --latest 5` |
| `TZ`                 | Timezone, e.g. "Europe/Vienna"                                   | UTC                                                                                    |
| `LOG_LEVEL`          | Logging verbosity: "quiet", "normal", or "debug"                 | normal                                                                                 |

**Note:** If `REFLECTOR_ARGS` is not set, the container uses the default parameters, which already produce a solid mirrorlist.

---

## 📂 **File Overview**
- **`Dockerfile`**: Builds the container with reflector, cron, and bash installed.
- **`entrypoint.sh`**: Handles either one-shot mode or setting up the cron job based on environment variables.
- **`reflector-update.sh`**: Runs reflector with the provided arguments, logs results, and rotates logs if needed.
- **`docker-compose.custom-build.yml`**: Example compose file for building the image locally and using volumes.

---

## 🌐 **Timezone and Logging**
You can set `TZ` to adjust the container’s timezone. Logs and cron will follow this timezone, making scheduling and debugging easier.  
For example, to use Vienna time:
```bash
-e TZ=Europe/Vienna
```

`LOG_LEVEL=debug` provides more verbose output, while `quiet` reduces output to errors only.

---

## 🔧 **Dockerfile Details**
- Installs `reflector` and `cronie`.
- Sets up directories for logs and scripts.
- Adds a healthcheck to ensure cron and mirrorlist updates are functioning properly.
- Allows caching and efficient CI/CD workflows.

---

## 💡 **Tips**
- **Adjust Scheduling**: Change `REFLECTOR_SCHEDULE` to run more frequently or less often as needed.
- **Customize Reflector Arguments**: Specify `REFLECTOR_ARGS` to filter by other countries, protocols, or sorting criteria.
- **Persistent Volume**: The volume `mirrorlist` ensures your mirrorlist persists across container updates or restarts.
- **Integration with Other Systems**: Use this image in CI/CD pipelines, or combine it with other containers that rely on fast Arch mirrors.

---

## 📜 **License**
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## 🤝 **Contributing**
Contributions are welcome! Feel free to open issues, submit pull requests, or suggest improvements. Let’s make Arch mirror management simpler and more efficient together! ✨

---

## 🙏 **Acknowledgments**
Inspired by similar Dockerized automation projects, this repository aims to provide a robust, flexible solution for managing Arch Linux mirrors in a containerized environment. Special thanks to [dezeroku/arch_linux_reflector_docker](https://github.com/dezeroku/arch_linux_reflector_docker) for the inspiration and foundational ideas. 🙌🎉

---

Happy updating, and may your Arch packages download at lightning speed! ⚡🐧
