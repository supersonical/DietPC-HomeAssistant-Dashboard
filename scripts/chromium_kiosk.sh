#!/usr/bin/env bash
set -euo pipefail

log() { echo "[chromium_kiosk] $*"; }

install_requirements() {
  log "Installing Chromium and X11 dependencies"
  apt-get update -y
  apt-get install -y chromium-browser || apt-get install -y chromium || true
  apt-get install -y xorg xinit unclutter x11-xserver-utils || true
}

write_custom_flags() {
  log "Writing /etc/chromium.d/custom-flags"
  mkdir -p /etc/chromium.d
  cat >/etc/chromium.d/custom-flags <<'EOF'
# Safe GPU acceleration flags
CHROMIUM_OPTS="$CHROMIUM_OPTS --enable-gpu-rasterization"
CHROMIUM_OPTS="$CHROMIUM_OPTS --ignore-gpu-blocklist"
CHROMIUM_OPTS="$CHROMIUM_OPTS --enable-accelerated-video-decode"

# Performance optimizations
CHROMIUM_OPTS="$CHROMIUM_OPTS --disk-cache-size=104857600"

# Kiosk improvements
CHROMIUM_OPTS="$CHROMIUM_OPTS --no-first-run"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-translate"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-session-crashed-bubble"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-default-apps"
CHROMIUM_OPTS="$CHROMIUM_OPTS --noerrdialogs"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-infobars"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-notifications"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-background-mode"
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-renderer-backgrounding"

# Hide scrollbars with CSS
CHROMIUM_OPTS="$CHROMIUM_OPTS --blink-settings=scrollbarThickness=0"

# Prioritize Active Page Loading
CHROMIUM_OPTS="$CHROMIUM_OPTS --disable-background-timer-throttling"
CHROMIUM_OPTS="$CHROMIUM_OPTS --enable-parallel-downloading"
CHROMIUM_OPTS="$CHROMIUM_OPTS --num-raster-threads=4"

# Disable Tabs and Force Single Page Mode
CHROMIUM_OPTS="$CHROMIUM_OPTS --block-new-web-contents"
CHROMIUM_OPTS="$CHROMIUM_OPTS --kiosk"
EOF
}

write_autostart_script() {
  local fp="/var/lib/dietpi/dietpi-software/installed/chromium-autostart.sh"
  log "Writing DietPi Chromium autostart script to $fp"
  mkdir -p /var/lib/dietpi/dietpi-software/installed
  cat >"$fp" <<'EOF'
#!/bin/dash
# Autostart script for kiosk mode, based on @AYapejian:  https://github.com/MichaIng/DietPi/issues/1737#issue-318697621

# Clear cache on startup to prevent memory bloat
rm -rf /root/.cache/chromium/Default/Cache/* 2>/dev/null
rm -rf /root/.config/chromium/Default/Service\ Worker/* 2>/dev/null
rm -rf /root/.config/chromium/Default/Code\ Cache/* 2>/dev/null

# Resolution to use for kiosk mode, should ideally match current system resolution
RES_X=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_X=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
RES_Y=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_Y=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

# Set VA-API driver
export LIBVA_DRIVER_NAME=i965

# Wait for network to be fully ready
sleep 2
while ! ping -c 1 -W 2 10.13.2.7 >/dev/null 2>&1; do
    echo "Waiting for network..."
    sleep 1
done

# Additional delay for network to stabilize
sleep 10

# Command line switches: https://peter.sh/experiments/chromium-command-line-switches/
# - Review and add custom flags in:  /etc/chromium.d
CHROMIUM_OPTS="--kiosk --window-size=${RES_X:-1280},${RES_Y:-720} --window-position=0,0"

# Load custom flags from /etc/chromium.d/
if [ -d /etc/chromium.d ]; then
    for i in /etc/chromium.d/*; do
        [ -r "$i" ] && . "$i"
    done
fi

# Home page
URL=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_AUTOSTART_URL=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

# RPi or Debian Chromium package
FP_CHROMIUM=$(command -v chromium-browser)
[ "$FP_CHROMIUM" ] || FP_CHROMIUM=$(command -v chromium)

# Use "startx" as non-root user to get required permissions via systemd-logind
STARTX='xinit'
[ "$USER" = 'root' ] || STARTX='startx'

# Disable screen blanking and hide cursor (after X starts)
(
    sleep 5
    export DISPLAY=:0
    xset s off -dpms s noblank 2>/dev/null
    unclutter -idle 0.1 -root 2>/dev/null &
) &

exec "$STARTX" "$FP_CHROMIUM" $CHROMIUM_OPTS "${URL:-http://10.13.2.7:8123}"
EOF
  chmod +x "$fp"
}

setup_kiosk_service() {
  local svc="chromium-kiosk.service"
  log "Creating systemd service for Chromium kiosk"
  cat >/etc/systemd/system/$svc <<'EOF'
[Unit]
Description=Chromium Kiosk Mode (DietPi Autostart)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/var/lib/dietpi/dietpi-software/installed/chromium-autostart.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable $svc
  systemctl restart $svc
}

main() {
  install_requirements
  write_custom_flags
  write_autostart_script
  setup_kiosk_service
}

main "$@"
