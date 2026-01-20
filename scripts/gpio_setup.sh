#!/usr/bin/env bash
set -euo pipefail

log() { echo "[gpio_setup] $*"; }

log "Installing GPIO libraries (Raspberry Pi)"
apt-get update -y
apt-get install -y pigpio python3-gpiozero

# Enable pigpio daemon at boot
systemctl enable pigpiod
systemctl start pigpiod

log "GPIO setup complete"
