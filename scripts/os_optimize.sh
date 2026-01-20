#!/usr/bin/env bash
set -euo pipefail

log() { echo "[os_optimize] $*"; }

# Update system
log "Updating system packages"
apt-get update -y
apt-get upgrade -y

# Enable auto login to console (DietPi)
if command -v dietpi-autostart >/dev/null 2>&1; then
  log "Configuring DietPi autostart to console (index 0)"
  dietpi-autostart 0 || true
fi

# Basic performance tweaks (placeholder)
log "Applying basic performance tweaks"
# Example: reduce GPU memory on headless systems
if [[ -f /boot/config.txt ]]; then
  sed -i 's/^gpu_mem=.*/gpu_mem=16/' /boot/config.txt || true
fi

log "OS optimizations complete"
