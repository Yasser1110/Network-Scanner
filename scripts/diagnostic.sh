#!/bin/bash
# Diagnostic script for WiFi Scanner Tool

echo "=== WiFi Scanner Diagnostic Tool ==="
echo ""

# System Info
echo "1. System Information:"
echo "   OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
echo "   Kernel: $(uname -r)"
echo "   Architecture: $(uname -m)"
echo ""

# Hardware Info
echo "2. Hardware Detection:"
echo "   USB WiFi Adapters:"
lsusb | grep -i "wireless\|wifi\|realtek\|rtl"
echo ""
echo "   PCI WiFi Adapters:"
lspci | grep -i "network\|wireless"
echo ""

# Driver Status
echo "3. Driver Status:"
echo "   Loaded WiFi modules:"
lsmod | grep -E "8188|rtl|ath|iwl|brcm"
echo ""
echo "   RTL8188EUS module:"
modinfo 8188eu 2>/dev/null | grep -E "filename|version" || echo "   Not loaded"
echo ""

# Interface Status
echo "4. Network Interfaces:"
ip link | grep -E "^[0-9]+:" | awk '{print "   " $0}'
echo ""
echo "   WiFi interfaces detail:"
iw dev 2>/dev/null | grep -A5 "Interface"
echo ""

# RF-kill Status
echo "5. RF-kill Status:"
rfkill list all
echo ""

# Service Status
echo "6. Service Status:"
systemctl is-active NetworkManager 2>/dev/null && echo "   NetworkManager: Active" || echo "   NetworkManager: Inactive"
systemctl is-active wpa_supplicant 2>/dev/null && echo "   wpa_supplicant: Active" || echo "   wpa_supplicant: Inactive"
echo ""

# Test Commands
echo "7. Test Commands:"
echo "   iw command: $(which iw 2>/dev/null || echo 'Not found')"
echo "   airodump-ng: $(which airodump-ng 2>/dev/null || echo 'Not found')"
echo "   rfkill: $(which rfkill 2>/dev/null || echo 'Not found')"
echo ""

# Recommendations
echo "8. Recommendations:"
if ! which airodump-ng >/dev/null 2>&1; then
    echo "   ❌ Install aircrack-ng: sudo apt-get install aircrack-ng"
fi
if rfkill list wifi | grep -q "Soft blocked: yes"; then
    echo "   ❌ WiFi is soft-blocked. Run: sudo rfkill unblock all"
fi
if ! lsmod | grep -q 8188eu; then
    echo "   ⚠️  RTL8188EUS driver not loaded"
fi
echo ""
echo "=== Diagnostic Complete ==="
echo "For more help, see docs/TROUBLESHOOTING.md"
