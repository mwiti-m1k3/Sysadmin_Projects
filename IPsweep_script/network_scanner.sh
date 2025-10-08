#!/bin/bash
# Script: network_scanner.sh
# Purpose: Performs a two-phase scan: fast host discovery, followed by detailed port scanning on live hosts.
# Usage: ./network_scanner.sh 192.168.1 (scans the 192.168.1.x subnet)

# --- Configuration ---
NETWORK_PREFIX=$1
TEMP_FILE="nmap_live_hosts.tmp"
OUTPUT_FILE="nmap_scan_$(date +%Y%m%d_%H%M%S).txt"

# --- 1. Validation and Setup ---

# Check if an argument was provided
if [ -z "$NETWORK_PREFIX" ]; then
    echo "Syntax Error: Network prefix not provided."
    echo "Usage: $0 192.168.1"
    exit 1
fi

# Check if Nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "Error: Nmap is not installed. Please install the 'nmap' package."
    exit 1
fi

echo "--- Phase 1: Starting fast host discovery for $NETWORK_PREFIX.0/24 ---"
echo "Using Nmap's Ping Scan (-sn) for reliability."

# --- 2. Fast Host Discovery (IP Sweep) ---
# nmap -sn: Ping Scan (host discovery only, no port scan)
# -oG: Output in Grepable format for easy parsing
nmap -sn "$NETWORK_PREFIX.1-254" -oG "$TEMP_FILE" > /dev/null

# Extract IP addresses marked as 'Up' from the temporary grepable output file
LIVE_IPS=$(grep "Up" "$TEMP_FILE" | awk '/Host:/{print $2}' | tr '\n' ' ')

if [ -z "$LIVE_IPS" ]; then
    echo "No active hosts found in the network $NETWORK_PREFIX.0/24."
    rm -f "$TEMP_FILE"
    exit 0
fi

# --- 3. Detailed Port Scan (Nmap Sweep) ---
HOST_COUNT=$(echo "$LIVE_IPS" | wc -w)
echo "--- Phase 2: $HOST_COUNT Active Host(s) Found. Starting detailed scan... ---"
echo "Live Hosts: $LIVE_IPS"
echo "Detailed Nmap output will be saved to $OUTPUT_FILE"

# Perform a detailed scan on the found hosts:
# -sC: Run default scripts (vulnerability, enumeration)
# -sV: Detect service versions (e.g., Apache 2.4.41)
# -O: Attempt to detect the operating system
# -iL: Read targets from a list (the temporary file)
# -oN: Output results to the specified file
nmap -sC -sV -O -iL "$TEMP_FILE" -oN "$OUTPUT_FILE"

# --- 4. Cleanup and Summary ---
echo ""
echo "--- Scan Complete ---"
echo "Detailed results for the $HOST_COUNT live host(s) saved to $OUTPUT_FILE"

# Clean up the temporary file
rm -f "$TEMP_FILE"
