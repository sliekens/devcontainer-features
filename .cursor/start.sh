#!/usr/bin/env bash
#
# Per-boot startup for the devcontainer-features Cloud Agent environment.
#
# Cloud Agent VMs are not managed by systemd, so the Docker daemon has to be
# launched by hand on every boot. This script starts dockerd (if it is not
# already running) and waits until the socket is ready. It is idempotent and
# returns once Docker is reachable.
#
set -euo pipefail

log() { printf '\033[0;34m[start]\033[0m %s\n' "$*"; }

DOCKERD_LOG="/tmp/dockerd.log"

if sudo docker info >/dev/null 2>&1; then
    log "Docker daemon already running"
    exit 0
fi

log "starting dockerd"
sudo rm -f /var/run/docker.pid
sudo nohup dockerd >"$DOCKERD_LOG" 2>&1 &

for i in $(seq 1 60); do
    if sudo docker info >/dev/null 2>&1; then
        log "Docker daemon ready after ${i}s"
        docker version --format 'Server: {{.Server.Version}} ({{.Server.Os}}/{{.Server.Arch}})' 2>/dev/null \
            || sudo docker version --format 'Server: {{.Server.Version}}'
        exit 0
    fi
    sleep 1
done

log "ERROR: Docker daemon did not become ready in time; recent log:"
tail -n 30 "$DOCKERD_LOG" || true
exit 1
