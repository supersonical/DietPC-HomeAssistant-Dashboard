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

# Intel graphics optimization for Bay Trail/Atom and disable screen blanking
log "Applying Intel X11 graphics optimizations"
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/20-intel.conf <<'EOF'
Section "Device"
    Identifier  "Intel Graphics"
    Driver      "modesetting"
    Option      "AccelMethod"  "glamor"
    Option      "DRI"          "3"
EndSection

Section "ServerFlags"
    Option "BlankTime"   "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
EndSection
EOF



log "Applying GRUB kernel parameters for i915"
if [[ -f /etc/default/grub ]]; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash i915.enable_guc=3 i915.enable_fbc=1"/' /etc/default/grub || true
  update-grub || true
fi

log "Setting CPU governor to performance"
if compgen -G "/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor" > /dev/null; then
  echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null || true
fi

log "Installing VA-API libraries and i965 driver"
apt-get update -y
apt-get install -y libva2 libva-drm2 libva-x11-2 vainfo || true
apt-get install -y --reinstall i965-va-driver || true

log "Installing post-boot checks service"
cat >/usr/local/bin/post_reboot_checks.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[post_reboot_checks] $*"; }

log "Checking Xorg error entries"
if [[ -f /var/log/Xorg.0.log ]]; then
  ERRORS=$(grep -E "\(EE\)" /var/log/Xorg.0.log || true)
  if [[ -n "$ERRORS" ]]; then
    log "Xorg reported errors:\n$ERRORS"
  else
    log "No Xorg (EE) errors found."
  fi
else
  log "Xorg log not found at /var/log/Xorg.0.log"
fi

log "Checking VA-API driver presence (i965)"
ls -la /usr/lib/x86_64-linux-gnu/dri/ | grep i965 || true
command -v vainfo >/dev/null 2>&1 && vainfo || log "vainfo not available"

log "Verifying disabled services"
for svc in bluetooth.service avahi-daemon.service; do
  if systemctl is-enabled "$svc" >/dev/null 2>&1; then
    log "Service $svc is still enabled (unexpected)." 
  else
    log "Service $svc is disabled as expected."
  fi
done

log "Post reboot checks complete"
EOF
chmod +x /usr/local/bin/post_reboot_checks.sh

cat >/etc/systemd/system/post-reboot-checks.service <<'EOF'
[Unit]
Description=Post reboot system checks for Xorg and VA-API
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/post_reboot_checks.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable post-reboot-checks.service || true

log "Rebooting system to apply changes"
shutdown -r now || true

log "OS optimizations complete"
