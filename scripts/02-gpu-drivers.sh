#!/bin/bash
#
# GPU Driver Installation Script for Intel Bay Trail
# Part of DietPC-HomeAssistant-Dashboard
#
# This script installs and configures Intel GPU drivers with VA-API
# hardware acceleration for Intel Bay Trail (Celeron N2xxx) processors.
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOGFILE="/var/log/dietpi-ha-dashboard-setup.log"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOGFILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOGFILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOGFILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGFILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_info "=========================================="
print_info "Intel Bay Trail GPU Driver Setup"
print_info "=========================================="
echo ""

# Detect CPU
print_info "Detecting CPU..."
CPU_INFO=$(lscpu | grep "Model name" || true)
print_info "$CPU_INFO"
echo ""

# Backup existing configurations
print_info "Creating backups of existing configurations..."
BACKUP_DIR="/root/dietpi-ha-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f /etc/modprobe.d/i915.conf ]; then
    cp /etc/modprobe.d/i915.conf "$BACKUP_DIR/"
    print_success "Backed up /etc/modprobe.d/i915.conf"
fi

if [ -d /etc/X11/xorg.conf.d ]; then
    cp -r /etc/X11/xorg.conf.d "$BACKUP_DIR/" 2>/dev/null || true
    print_success "Backed up /etc/X11/xorg.conf.d/"
fi

print_success "Backups stored in: $BACKUP_DIR"
echo ""

# Install required packages
print_info "Installing Intel GPU drivers and tools..."
apt-get update -qq
apt-get install -y \
    xserver-xorg-video-intel \
    mesa-va-drivers \
    i965-va-driver \
    vainfo \
    intel-gpu-tools \
    mesa-utils \
    libva2 \
    libva-drm2 \
    libva-x11-2

print_success "GPU drivers and tools installed"
echo ""

# Configure i915 kernel module
print_info "Configuring i915 kernel module..."
mkdir -p /etc/modprobe.d

cat > /etc/modprobe.d/i915.conf << 'EOF'
# Intel i915 driver options for Bay Trail
# Optimized for stability and performance on low-power devices

options i915 enable_guc=0 enable_fbc=1 fastboot=1
EOF

print_success "Created /etc/modprobe.d/i915.conf"
echo ""

# Configure Xorg Intel driver
print_info "Configuring Xorg Intel driver..."
mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/20-intel.conf << 'EOF'
Section "Device"
    Identifier  "Intel Graphics"
    Driver      "intel"
    Option      "AccelMethod"  "sna"
    Option      "TearFree"     "true"
    Option      "DRI"          "3"
EndSection
EOF

print_success "Created /etc/X11/xorg.conf.d/20-intel.conf"
echo ""

# Verify installation
print_info "Verifying GPU driver installation..."
echo ""

# Check if i915 module is loaded
if lsmod | grep -q i915; then
    print_success "i915 kernel module is loaded"
else
    print_warning "i915 kernel module not loaded (will load on reboot)"
fi

# Check VA-API support
print_info "Checking VA-API support..."
if command -v vainfo &> /dev/null; then
    print_success "vainfo is installed"
    
    # Set VA-API driver
    export LIBVA_DRIVER_NAME=i965
    
    # Test VA-API (will work fully after reboot with X running)
    if vainfo 2>&1 | grep -q "i965"; then
        print_success "VA-API driver i965 detected"
    else
        print_warning "VA-API will be fully available after reboot"
    fi
else
    print_error "vainfo not found"
fi

echo ""

# Check OpenGL support
print_info "Checking OpenGL support..."
if command -v glxinfo &> /dev/null; then
    print_success "glxinfo is installed"
else
    print_warning "glxinfo not found"
fi

echo ""

# Summary
print_info "=========================================="
print_info "GPU Driver Installation Summary"
print_info "=========================================="
print_success "✓ Intel GPU drivers installed"
print_success "✓ VA-API drivers (i965) installed"
print_success "✓ i915 kernel module configured"
print_success "✓ Xorg Intel driver configured"
print_success "✓ GPU tools installed (vainfo, intel_gpu_top)"
echo ""

print_warning "IMPORTANT: Reboot required for GPU changes to take full effect"
echo ""

print_info "After reboot, verify GPU acceleration with:"
echo "  export LIBVA_DRIVER_NAME=i965"
echo "  vainfo"
echo "  glxinfo | grep OpenGL"
echo "  intel_gpu_top"
echo ""

print_info "Backups stored in: $BACKUP_DIR"
print_info "Log file: $LOGFILE"
echo ""

# Ask for reboot
read -p "Would you like to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Rebooting system..."
    reboot
else
    print_info "Please reboot manually when ready: sudo reboot"
fi
