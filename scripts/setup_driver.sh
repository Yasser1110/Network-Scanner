#!/bin/bash
# RTL8188EUS Driver Setup Helper

echo "=== RTL8188EUS Driver Setup ==="
echo ""

# Check if in driver directory
if [ ! -f "Makefile" ] && [ -d "../drivers/rtl8188eus" ]; then
    cd ../drivers/rtl8188eus
fi

if [ ! -f "Makefile" ]; then
    echo "Error: Makefile not found. Are you in the driver directory?"
    exit 1
fi

echo "1. Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential git dkms linux-headers-$(uname -r)

echo "2. Cleaning previous builds..."
sudo make clean

echo "3. Building driver..."
sudo make

echo "4. Installing driver..."
sudo make install

echo "5. Loading module..."
sudo modprobe -r 8188eu 2>/dev/null
sudo modprobe 8188eu

echo "6. Verifying installation..."
if lsmod | grep -q 8188eu; then
    echo "✅ Driver loaded successfully!"
    echo "   Module: $(modinfo -n 8188eu 2>/dev/null)"
else
    echo "❌ Driver failed to load. Check dmesg for errors:"
    echo "   sudo dmesg | tail -20"
fi

echo ""
echo "=== Setup Complete ==="
