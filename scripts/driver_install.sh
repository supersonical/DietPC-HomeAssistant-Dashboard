#!/usr/bin/env bash
set -euo pipefail

log() { echo "[driver_install] $*"; }

log "Installing common drivers and firmware"
apt-get update -y
apt-get install -y firmware-linux-free

# Placeholder for device-specific drivers
# Example: touchscreens, Wi-Fi dongles, display adapters

log "Driver installation complete"
