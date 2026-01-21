# WiFi Security Scanner Tool

![WiFi Security](https://img.shields.io/badge/WiFi-Security-blue)
![Bash](https://img.shields.io/badge/Bash-Scripting-green)
![Linux](https://img.shields.io/badge/Linux-Compatible-orange)

A professional, automated WiFi security assessment tool that performs wireless network scanning, vulnerability detection, and generates detailed security reports.

## 🚀 Features

- **Automated Monitor Mode**: Configures WiFi adapter for packet capture
- **Vulnerability Detection**: Identifies WEP, open networks, and weak configurations
- **Time-limited Scanning**: Scans for specified duration with auto-restoration
- **Professional Reporting**: Generates detailed vulnerability reports with risk analysis
- **RF-kill Management**: Handles WiFi blocking/unblocking automatically
- **Safe Operation**: Always restores system to original state after scanning
- **Multiple Output Formats**: CSV data and human-readable reports

## 📋 Requirements

### Hardware
- TP-Link TL-WN722N v2/v3 (RTL8188EUS chipset) or similar
- Any monitor-mode capable WiFi adapter
- USB port (for external adapters)

### Software
- Linux (Tested on Ubuntu 22.04/24.04)
- `iw` and `aircrack-ng` suite
- `rfkill` utility
- NetworkManager (for service control)

## 🛠️ Installation

### 1. Driver Installation (for RTL8188EUS adapters)
```bash
cd drivers/rtl8188eus
sudo make clean
sudo make
sudo make install
sudo modprobe -r 8188eu
sudo modprobe 8188eu

# Make the installation script executable
chmod +x install.sh

# Run the installer
sudo ./install.sh

# Test with 1-minute scan
sudo wifiscan 1

# Basic Scanning (5 mins default)
sudo wifiscan

#Custom Duration Scan
sudo wifiscan 10    # 10-minute scan
sudo wifiscan 2     # 2-minute scan
#Quick Demo
sudo wifiscan 10    # 10-minute scan
sudo wifiscan 2     # 2-minute scan
