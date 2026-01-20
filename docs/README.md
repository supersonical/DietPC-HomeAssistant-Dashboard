# DietPI Home Assistant Dashboard Setup

This documentation will guide you through the installation and configuration process using the provided scripts.

## Overview

This repo contains scripts to automate the setup of DietPI for running a Home Assistant dashboard. It includes a main setup script and individual configuration scripts for various components like GPIO, Chromium kiosk mode, drivers, and OS optimizations.

## Prerequisites

- Fresh DietPi installation on a supported device (e.g., Raspberry Pi)
- Internet connectivity
- SSH access or local terminal

## How to Use

1. Clone the repository:

```
git clone https://github.com/supersonical/DietPC-HomeAssistant-Dashboard.git
cd DietPC-HomeAssistant-Dashboard
```

2. Run the main setup script:

```
sudo bash setup.sh
```

3. Follow on-screen prompts to select and apply specific configurations.

## Structure

- `setup.sh` - Main installation script orchestrating configuration steps.
- `configs/` - Configuration files (GPIO, Chromium, drivers, OS optimizations).
- `scripts/` - Individual scripts for applying configurations.
- `docs/` - Documentation and guides.
- `README.md` - Quick start instructions and repo overview.

## Contributing

Feel free to submit PRs to improve scripts, add device support, or enhance documentation.
