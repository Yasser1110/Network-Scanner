#!/bin/bash

# WiFi Security Scanner Tool - Installation Script
# Version: 1.1.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

print_header() {
    echo -e "${BLUE}"
    echo "============================================"
    echo "   WiFi Security Scanner Tool Installer"
    echo "============================================"
    echo -e "${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    apt-get update
    
    # Required packages
    apt-get install -y \
        wireless-tools \
        iw \
        aircrack-ng \
        rfkill \
        curl \
        git \
        make \
        gcc \
        linux-headers-$(uname -r)
    
    print_status "Dependencies installed"
}

install_driver() {
    print_status "Checking for RTL8188EUS driver..."
    
    if [ -d "drivers/rtl8188eus" ]; then
        print_status "Building RTL8188EUS driver..."
        cd drivers/rtl8188eus
        
        # Clean previous builds
        make clean 2>/dev/null || true
        
        # Build and install
        make
        make install
        
        # Load module
        modprobe -r 8188eu 2>/dev/null || true
        modprobe 8188eu
        
        cd ../..
        print_status "Driver installed successfully"
    else
        print_warning "RTL8188EUS driver source not found"
        print_warning "Using system driver (monitor mode may not work)"
    fi
}

install_tool() {
    print_status "Installing WiFi Security Scanner..."
    
    # Copy main script
    cp src/wifi_scanner_fixed.sh /usr/local/bin/wifiscan
    chmod +x /usr/local/bin/wifiscan
    
    # Create scan directory
    mkdir -p /home/$SUDO_USER/wifi-scans
    chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/wifi-scans
    
    # Create examples directory
    mkdir -p /usr/local/share/wifiscan/examples
    cp examples/* /usr/local/share/wifiscan/examples/ 2>/dev/null || true
    
    print_status "Tool installed to /usr/local/bin/wifiscan"
}

create_service() {
    print_status "Creating WiFi unblock service..."
    
    cat > /etc/systemd/system/wifi-unblock.service << 'SERVICE_EOF'
[Unit]
Description=Keep WiFi unblocked for security scanning
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock all
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    
    systemctl daemon-reload
    systemctl enable wifi-unblock.service
    print_status "WiFi unblock service created"
}

print_success() {
    echo -e "${GREEN}"
    echo "============================================"
    echo "   Installation Completed Successfully!"
    echo "============================================"
    echo -e "${NC}"
    echo "🎉 WiFi Security Scanner Tool is now installed!"
    echo ""
    echo "📖 Quick Start:"
    echo "   sudo wifiscan 1    # Run 1-minute test scan"
    echo ""
    echo "📁 Output directory:"
    echo "   ~/wifi-scans/"
    echo ""
    echo "❓ Help:"
    echo "   wifiscan --help    # Show usage information"
    echo ""
    echo "⚠️  LEGAL DISCLAIMER:"
    echo "   Use only on networks you own or have permission to test!"
    echo ""
}

main() {
    print_header
    check_root
    
    echo "This will install:"
    echo "1. Required dependencies"
    echo "2. RTL8188EUS driver (if available)"
    echo "3. WiFi Security Scanner Tool"
    echo "4. System service for WiFi management"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 0
    fi
    
    install_dependencies
    install_driver
    install_tool
    create_service
    print_success
}

main "$@"
