# 📡 Network Scanning Process for Linux: Integrated Nmap Script

This project provides a reliable and efficient two-phase network scanning script for Linux systems, integrating Nmap for both host discovery and detailed port/service scanning.

## 🎯 Project Goal

This script aims to:
*   Perform a fast initial IP sweep to identify active hosts within a specified subnet.
*   Execute a detailed Nmap port, service, and OS scan exclusively on those live hosts, saving time and resources.
*   Log all detailed scan results to a timestamped file for easy review and record-keeping.
*   Provide a robust, "Linux-native" approach to network reconnaissance using Nmap's powerful features.

## 💻 Applicable Systems

*   **Linux:** This script is designed specifically for Linux environments (e.g., Ubuntu, Debian, CentOS, Fedora, Kali Linux).
*   **macOS:** With Nmap installed, this script should also function correctly on macOS.

## ⚙️ Prerequisites

*   **Nmap:** The Nmap network scanning tool must be installed on your system. You can usually install it via your distribution's package manager (e.g., `sudo apt install nmap` on Debian/Ubuntu, `sudo yum install nmap` on CentOS/RHEL).
*   **Bash:** A Bash-compatible shell (standard on most Linux distributions and macOS).
*   **Permissions:** You may need `sudo` privileges to run Nmap effectively, especially for OS detection or certain scan types. It's often run as root for full functionality.

## 🚀 Usage/Instructions

### 1. Save the Script

Save the following content into a file named `network_scanner.sh` on your Linux/macOS system:

```bash
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
```

### 2. Make it Executable

Open your terminal, navigate to the directory where you saved `network_scanner.sh`, and run:

```bash
chmod +x network_scanner.sh
```

### 3. Execute the Script

Run the script by providing the first three octets of your target network as an argument.

**Example for a network ranging from `192.168.1.1` to `192.168.1.254`:**

```bash
./network_scanner.sh 192.168.1
```

You might need to use `sudo` for full Nmap functionality (e.g., `sudo ./network_scanner.sh 192.168.1`).

### 4. Check Results

After execution, a file named like `nmap_scan_YYYYMMDD_HHMMSS.txt` (e.g., `nmap_scan_20240415_103025.txt`) will be created in the same directory, containing the full, detailed Nmap scan for all active hosts.

---

## 🖥️ Example Output

When you run the script, you will see real-time output in your terminal:

```
--- Phase 1: Starting fast host discovery for 192.168.1.0/24 ---
Using Nmap's Ping Scan (-sn) for reliability.
--- Phase 2: 3 Active Host(s) Found. Starting detailed scan... ---
Live Hosts: 192.168.1.1 192.168.1.100 192.168.1.105 
Detailed Nmap output will be saved to nmap_scan_20240423_143501.txt

Starting Nmap 7.80 ( https://nmap.org ) at 2024-04-23 14:35 EDT
Nmap scan report for _gateway (192.168.1.1)
Host is up (0.00030s latency).
Not shown: 997 closed ports
PORT      STATE SERVICE VERSION
22/tcp    open  ssh     OpenSSH 7.6p1 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http    Apache httpd 2.4.29 ((Ubuntu))
443/tcp   open  ssl/http Apache httpd 2.4.29 ((Ubuntu))
Device type: general purpose
Running: Linux 4.X
OS CPE: cpe:/o:linux:linux_kernel:4
OS details: Linux 4.15 - 4.18
Network Distance: 1 hop

Nmap scan report for MyServer (192.168.1.100)
Host is up (0.00025s latency).
All 1000 scanned ports on MyServer (192.168.1.100) are closed.
Device type: general purpose
Running: Linux 3.X|4.X
OS CPE: cpe:/o:linux:linux_kernel:3:0
OS details: Linux 3.2 - 4.9

Nmap scan report for MyWorkstation (192.168.1.105)
Host is up (0.00018s latency).
Not shown: 999 closed ports
PORT   STATE SERVICE VERSION
3389/tcp open ms-wbt-server Microsoft Terminal Services (RDP)
Device type: general purpose
Running: Microsoft Windows 7|8.1
OS CPE: cpe:/o:microsoft:windows_7:::sp1|cpe:/o:microsoft:windows_8.1
OS details: Microsoft Windows 7 SP1 or Windows 8.1
Network Distance: 1 hop

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 3 IP addresses (3 hosts up) scanned in 10.56 seconds
--- Scan Complete ---
Detailed results for the 3 live host(s) saved to nmap_scan_20240423_143501.txt
```

The `nmap_scan_YYYYMMDD_HHMMSS.txt` file will contain the full Nmap output as shown in the latter part of the example above.

---

## ⚠️ Notes/Warnings

*   **Network Range:** This script scans the `.1` to `.254` range of the provided network prefix. Adjust `"$NETWORK_PREFIX.1-254"` in the script if you need a different range.
*   **Performance:** Detailed Nmap scans (`-sC`, `-sV`, `-O`) can take a significant amount of time, especially on larger networks or with many active hosts.
*   **Legality and Ethics:** Always ensure you have explicit permission to scan any network. Unauthorized scanning is illegal and unethical. Use this script responsibly and only on networks you own or have permission to test.
*   **Firewalls/IDS:** Network scans can be detected by firewalls and Intrusion Detection Systems (IDS). Be aware of the environment you are scanning.
*   **Temporary Files:** The script creates a temporary file (`nmap_live_hosts.tmp`) to store live IPs, which is automatically removed upon completion.
*   **Customization:** The Nmap detailed scan flags (`-sC -sV -O`) are a good general starting point. You can modify these flags within the script to suit your specific needs (e.g., `-p 1-1000` for specific ports, `-T4` for faster timing).

---

## 🚀 Further Exploration

*   **Port Specification:** Modify the script to allow a user to specify a list of ports to scan (e.g., `nmap -p 22,80,443 -sC -sV -O -iL "$TEMP_FILE" -oN "$OUTPUT_FILE"`).
*   **XML Output:** Change the output format to XML (`-oX`) for easier programmatic parsing, which could be useful for integrating with other tools or scripts.
*   **Error Handling:** Enhance the script's error handling for Nmap failures or unexpected output.
*   **Log Parsing:** Develop a Python or PowerShell script to parse the generated Nmap output file and extract specific information (e.g., open ports, service versions, OS details) into a more structured format (CSV, JSON).
*   **Target List Input:** Modify the script to accept a file containing a list of target IPs or CIDR ranges instead of just a single `/24` prefix.
```
