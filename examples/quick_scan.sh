#!/bin/bash
# Quick test script
echo "=== Quick WiFi Scan Test ==="
echo "1. Checking RF-kill..."
sudo rfkill unblock all
echo "2. Stopping NetworkManager..."
sudo systemctl stop NetworkManager
echo "3. Setting monitor mode..."
sudo ip link set wlx98038e9e58c8 down
sudo iw dev wlx98038e9e58c8 set type monitor
sudo ip link set wlx98038e9e58c8 up
echo "4. Quick 30-second scan..."
timeout 30 sudo airodump-ng wlx98038e9e58c8 --band abg
echo "5. Restoring..."
sudo ip link set wlx98038e9e58c8 down
sudo iw dev wlx98038e9e58c8 set type managed
sudo ip link set wlx98038e9e58c8 up
sudo systemctl start NetworkManager
echo "=== Done ==="
