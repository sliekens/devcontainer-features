#!/usr/bin/env bash
#
# Docker daemon supervisor for the devcontainer-features Cloud Agent
# environment, run as a persistent tmux-backed terminal.
#
# The `start` phase (start.sh) normally brings dockerd up first; in that case
# this just tails the daemon log so it stays visible. If dockerd is not running
# (for example on a boot where the start command did not fire), this launches
# dockerd in the foreground so the terminal keeps it alive for the environment's
# lifetime.
#
set -uo pipefail

DOCKERD_LOG="/var/log/dockerd.log"
sudo touch "$DOCKERD_LOG" 2>/dev/null || true

if sudo docker info >/dev/null 2>&1; then
    echo "[dockerd] already running (started by start.sh); tailing ${DOCKERD_LOG}"
    exec sudo tail -n +1 -F "$DOCKERD_LOG"
fi

echo "[dockerd] not running; starting in foreground"
sudo rm -f /var/run/docker.pid
exec sudo dockerd
