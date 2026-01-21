#!/bin/bash

# ============================================
# WIFI Monitor Mode Scanner
# Usage: sudo ./wifi_scanner.sh [duration_minutes]
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCAN_DURATION=${1:-5}  # Default 5 minutes if not specified
TP_LINK_INTERFACE="wlx98038e9e58c8"
TP_LINK_MAC="98:03:8e:9e:58:c8"
MONITOR_INTERFACE="${TP_LINK_INTERFACE}mon"
SCAN_OUTPUT_DIR="$HOME/Desktop/Netowrk_Scan/scans"
SCAN_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCAN_FILE="$SCAN_OUTPUT_DIR/scan_${SCAN_TIMESTAMP}.csv"
REPORT_FILE="$SCAN_OUTPUT_DIR/report_${SCAN_TIMESTAMP}.txt"

# Function to print header
print_header() {
    echo -e "${CYAN}"
    echo "============================================"
    echo "    WIFI SECURITY SCANNER v1.0"
    echo "============================================"
    echo -e "${NC}"
}

# Function to print status
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Function to estimate time
estimate_time() {
    local duration=$1
    local setup_time=30  # seconds for setup
    local cleanup_time=20 # seconds for cleanup
    local total_seconds=$((duration * 60 + setup_time + cleanup_time))
    
    echo -e "${BLUE}[*] Estimated total time:${NC}"
    echo "    - Scan duration: $duration minutes"
    echo "    - Setup time: 30 seconds"
    echo "    - Cleanup time: 20 seconds"
    echo "    - Total: $(($total_seconds / 60)) minutes $(($total_seconds % 60)) seconds"
    echo ""
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Function to create output directory
setup_environment() {
    mkdir -p "$SCAN_OUTPUT_DIR"
    print_status "Output directory: $SCAN_OUTPUT_DIR"
}

# Function to stop interfering services
stop_interfering_services() {
    print_status "Stopping network services that may interfere..."
    
    # List of services to stop
    services=("NetworkManager" "wpa_supplicant" "avahi-daemon")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            systemctl stop "$service" 2>/dev/null
            print_status "Stopped: $service"
        fi
    done
    
    # Kill processes that may interfere
    airmon-ng check kill > /dev/null 2>&1
}

# Function to setup monitor mode
setup_monitor_mode() {
    print_status "Setting up monitor mode..."
    
    # Check if interface exists
    if ! ip link show "$TP_LINK_INTERFACE" > /dev/null 2>&1; then
        print_error "Interface $TP_LINK_INTERFACE not found!"
        exit 1
    fi
    
    # Bring interface down
    ip link set "$TP_LINK_INTERFACE" down
    
    # Set monitor mode
    if iw dev "$TP_LINK_INTERFACE" set type monitor; then
        print_status "Monitor mode enabled on $TP_LINK_INTERFACE"
    else
        # Try airmon-ng as fallback
        print_warning "Trying alternative method..."
        airmon-ng start "$TP_LINK_INTERFACE" > /dev/null 2>&1
        
        # Check for monitor interface
        if ip link show "${TP_LINK_INTERFACE}mon" > /dev/null 2>&1; then
            MONITOR_INTERFACE="${TP_LINK_INTERFACE}mon"
            print_status "Monitor interface: $MONITOR_INTERFACE"
        else
            print_error "Failed to enable monitor mode"
            exit 1
        fi
    fi
    
    # Bring interface up
    ip link set "$TP_LINK_INTERFACE" up
    iwconfig "$TP_LINK_INTERFACE" channel 6  # Set to common channel
    
    print_status "Monitor mode setup complete"
}

# Function to perform scan
perform_scan() {
    local duration=$1
    local scan_seconds=$((duration * 60))
    
    print_status "Starting scan for $duration minutes..."
    echo -e "${BLUE}[*] Scanning on channel hop...${NC}"
    
    # Start airodump-ng with channel hopping
    timeout $scan_seconds airodump-ng "$TP_LINK_INTERFACE" \
        --write "$SCAN_FILE" \
        --output-format csv \
        --band abg \
        --write-interval 5 \
        --berlin 10 \
        --channel 1,6,11 2>/dev/null &
    
    SCAN_PID=$!
    
    # Show progress
    echo -e "${YELLOW}[*] Scan in progress... (Press Ctrl+C to stop early)${NC}"
    
    # Progress bar
    for ((i=0; i<duration; i++)); do
        for ((j=0; j<12; j++)); do  # 12 * 5 = 60 seconds
            sleep 5
            echo -n "#"
        done
        echo " [$(($i+1))/$duration min]"
    done
    
    wait $SCAN_PID 2>/dev/null
    print_status "Scan completed"
}

# Function to analyze results
analyze_results() {
    print_status "Analyzing scan results..."
    
    if [ ! -f "$SCAN_FILE-01.csv" ]; then
        print_error "No scan data found!"
        return
    fi
    
    # Parse the CSV file
    local csv_file="$SCAN_FILE-01.csv"
    
    echo -e "${CYAN}"
    echo "============================================"
    echo "           VULNERABILITY REPORT"
    echo "============================================"
    echo -e "${NC}"
    
    # Count total networks
    total_networks=$(grep -c "^[0-9A-F:]\{17\}" "$csv_file" 2>/dev/null || echo "0")
    echo -e "${BLUE}[*] Total networks found:${NC} $total_networks"
    echo ""
    
    # Check for WEP networks (highly vulnerable)
    wep_count=$(grep -c "WEP" "$csv_file" 2>/dev/null || echo "0")
    if [ "$wep_count" -gt 0 ]; then
        echo -e "${RED}[CRITICAL] WEP Networks Found: $wep_count${NC}"
        grep "WEP" "$csv_file" | awk -F',' '{print "  - BSSID: " $1 " | ESSID: " $14}'
        echo "  -> WEP is extremely vulnerable to cracking!"
        echo ""
    fi
    
    # Check for open networks (no encryption)
    open_count=$(grep -c "OPN" "$csv_file" 2>/dev/null || echo "0")
    if [ "$open_count" -gt 0 ]; then
        echo -e "${RED}[HIGH RISK] Open Networks: $open_count${NC}"
        grep "OPN" "$csv_file" | awk -F',' '{print "  - BSSID: " $1 " | ESSID: " $14}'
        echo "  -> No encryption - all traffic is visible!"
        echo ""
    fi
    
    # Check for WPA networks with weak configurations
    wpa_count=$(grep -c "WPA" "$csv_file" 2>/dev/null || echo "0")
    if [ "$wpa_count" -gt 0 ]; then
        echo -e "${YELLOW}[MEDIUM RISK] WPA/WPA2 Networks: $wpa_count${NC}"
        
        # Check for WPS enabled networks
        wps_count=$(strings "$csv_file" | grep -c "WPS" 2>/dev/null || echo "0")
        if [ "$wps_count" -gt 0 ]; then
            echo "  -> $wps_count networks have WPS enabled (potential vulnerability)"
        fi
        
        # Check for default/common SSIDs
        common_ssids=("linksys" "dlink" "netgear" "default" "wireless" "home")
        for ssid in "${common_ssids[@]}"; do
            count=$(grep -i "$ssid" "$csv_file" 2>/dev/null | wc -l || echo "0")
            if [ "$count" -gt 0 ]; then
                echo "  -> Found $count networks with common SSID: '$ssid'"
            fi
        done
        echo ""
    fi
    
    # Check for hidden networks
    hidden_count=$(grep -c "^[0-9A-F:]\{17\},.*,\$" "$csv_file" 2>/dev/null || echo "0")
    if [ "$hidden_count" -gt 0 ]; then
        echo -e "${YELLOW}[INFO] Hidden Networks: $hidden_count${NC}"
        echo "  -> Hidden SSIDs can still be discovered"
        echo ""
    fi
    
    # Show strongest signals (potential nearby targets)
    echo -e "${GREEN}[*] Strongest signals (closest networks):${NC}"
    grep "^[0-9A-F:]\{17\}" "$csv_file" 2>/dev/null | sort -t',' -k9 -nr | head -5 | awk -F',' '{
        printf "  - %s | %s | Signal: %s | Channel: %s\n", $1, $14, $9, $4
    }'
    echo ""
    
    # Generate report file
    {
        echo "WIFI Security Scan Report"
        echo "========================="
        echo "Scan Date: $(date)"
        echo "Duration: $SCAN_DURATION minutes"
        echo "Interface: $TP_LINK_INTERFACE"
        echo ""
        echo "SUMMARY:"
        echo "Total Networks: $total_networks"
        echo "WEP Networks: $wep_count"
        echo "Open Networks: $open_count"
        echo "WPA/WPA2 Networks: $wpa_count"
        echo "Hidden Networks: $hidden_count"
        echo ""
        echo "RECOMMENDATIONS:"
        [ "$wep_count" -gt 0 ] && echo "1. WEP networks should be upgraded to WPA2/WPA3 immediately"
        [ "$open_count" -gt 0 ] && echo "2. Open networks should enable WPA2 encryption"
        [ "$wps_count" -gt 0 ] && echo "3. Disable WPS on routers as it can be vulnerable"
        echo "4. Use strong passwords (12+ characters, mix of types)"
        echo "5. Regularly update router firmware"
        echo "6. Disable remote administration"
    } > "$REPORT_FILE"
    
    print_status "Detailed report saved to: $REPORT_FILE"
}

# Function to restore normal mode
restore_normal_mode() {
    print_status "Restoring normal mode..."
    
    # Kill any remaining scanning processes
    pkill -f "airodump-ng" 2>/dev/null
    
    # Bring interface down
    ip link set "$TP_LINK_INTERFACE" down 2>/dev/null
    
    # Set back to managed mode
    iw dev "$TP_LINK_INTERFACE" set type managed 2>/dev/null
    
    # Bring interface up
    ip link set "$TP_LINK_INTERFACE" up 2>/dev/null
    
    # Restart network services
    print_status "Restarting network services..."
    systemctl start NetworkManager 2>/dev/null
    systemctl start wpa_supplicant 2>/dev/null
    
    print_status "Normal mode restored"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Kill all child processes
    pkill -P $$ 2>/dev/null
    
    # Ensure normal mode is restored
    restore_normal_mode
    
    # Remove temporary monitor interface if exists
    if ip link show "${TP_LINK_INTERFACE}mon" > /dev/null 2>&1; then
        iw dev "${TP_LINK_INTERFACE}mon" del 2>/dev/null
    fi
    
    print_status "Cleanup complete"
}

# Trap Ctrl+C for graceful exit
trap 'echo -e "\n${YELLOW}[!] Interrupted by user${NC}"; cleanup; exit 0' INT

# Main execution
main() {
    print_header
    check_root
    estimate_time "$SCAN_DURATION"
    setup_environment
    
    # Ask for confirmation
    read -p "$(echo -e ${YELLOW}"Press Enter to start scan or Ctrl+C to cancel..."${NC})" 
    echo ""
    
    # Execute steps
    stop_interfering_services
    setup_monitor_mode
    perform_scan "$SCAN_DURATION"
    analyze_results
    cleanup
    
    echo -e "${GREEN}"
    echo "============================================"
    echo "          SCAN COMPLETED SUCCESSFULLY"
    echo "============================================"
    echo -e "${NC}"
    echo "Output files:"
    echo "  - Scan data: $SCAN_FILE-01.csv"
    echo "  - Report: $REPORT_FILE"
    echo ""
    echo "All network interfaces have been restored to normal mode."
}

# Run main function
main "$@"
