# Setup Guide

## Quick Setup
1. Clone or download the project
2. Run the installer: `sudo ./install.sh`
3. Test with: `sudo wifiscan 1`

## Manual Setup
### 1. Install dependencies:
```bash
sudo apt-get install wireless-tools iw aircrack-ng rfkill
###2. Build driver (for RTL8188EUS):
bash

cd drivers/rtl8188eus
sudo make clean
sudo make
sudo make install
sudo modprobe 8188eu

###3. Install scanner:
bash

sudo cp src/wifi_scanner_fixed.sh /usr/local/bin/wifiscan
sudo chmod +x /usr/local/bin/wifiscan

###Testing

###  Quick test: sudo ./examples/quick_scan.sh
##
#    Diagnostic: ./scripts/diagnostic.sh
#
#    Full scan: sudo wifiscan 5
