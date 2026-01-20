#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts"
CONFIGS_DIR="$REPO_ROOT/configs"

log() { echo "[setup] $*"; }
err() { echo "[error] $*" >&2; }

die() { err "$1"; exit 1; }

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    die "Please run as root (sudo bash setup.sh)."
  fi
}

require_dietpi() {
  if ! grep -qi "dietpi" /etc/os-release 2>/dev/null; then
    log "DietPi not detected in /etc/os-release. Proceeding, but scripts are targeted for DietPi."
  fi
}

show_menu() {
  cat <<EOF
DietPI Home Assistant Dashboard Setup
-------------------------------------
Select an action:
1) Update & basic OS optimizations
2) Install Chromium kiosk mode
3) Configure GPIO support
4) Install additional drivers
5) All of the above
6) Exit
EOF
}

run_script() {
  local script="$1"
  if [[ -x "$SCRIPTS_DIR/$script" ]]; then
    log "Running $script"
    "$SCRIPTS_DIR/$script"
  else
    die "Script $script not found or not executable in $SCRIPTS_DIR"
  fi
}

main() {
  require_root
  require_dietpi

  while true; do
    show_menu
    read -rp "Enter choice [1-6]: " choice
    case "$choice" in
      1) run_script os_optimize.sh ;;
      2) run_script chromium_kiosk.sh ;;
      3) run_script gpio_setup.sh ;;
      4) run_script driver_install.sh ;;
      5)
        run_script os_optimize.sh
        run_script chromium_kiosk.sh
        run_script gpio_setup.sh
        run_script driver_install.sh
        ;;
      6) log "Exiting."; exit 0 ;;
      *) err "Invalid choice" ;;
    esac
  done
}

main "$@"
