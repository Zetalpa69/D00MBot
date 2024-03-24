#!/bin/bash

# Function to validate URL format
validate_url() {
    local url=$1
    if [[ $url =~ ^https?:// ]]; then
        return 0
    else
        echo "Error: Invalid URL format. Please enter a valid URL starting with 'http://' or 'https://'."
        return 1
    fi
}

# Function to validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0
    else
        echo "Error: Invalid IP address format. Please enter a valid IP address."
        return 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to perform web application pentesting
web_app_pentest() {
    echo "Enter the URL to pentest:"
    read url

    # Validate URL input
    if ! validate_url "$url"; then
        return 1
    fi

    # Dependency check
    local required_tools=("gobuster" "nikto" "assetfinder" "httprobe" "anew")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            echo "Error: Required tool ($tool) is not installed. Please install it and try again."
            return 1
        fi
    done

    # Create directory for scans
    scan_dir="Scans"
    mkdir -p "$scan_dir"

    # Create file for scan results
    scan_results="$scan_dir/web_app_scan.txt"
    touch "$scan_results"

    # Additional options
    read -p "Do you want to enable IP spoofing and decoy? (y/n): " spoof_choice
    if [[ $spoof_choice == "y" || $spoof_choice == "Y" ]]; then
        echo "Enter the IP address of the decoy server:"
        read decoy_ip

        # Validate decoy IP input
        if ! validate_ip "$decoy_ip"; then
            echo "Error: Invalid decoy IP address. Exiting."
            return 1
        fi

        # Enable IP spoofing and decoy
        iptables -t nat -A PREROUTING -s "$decoy_ip" -j ACCEPT
        iptables -t nat -A PREROUTING -s ! "$decoy_ip" -j DNAT --to-destination "$decoy_ip"
    fi

    # Directory busting
    echo "Performing directory busting..."
    gobuster dir -u "$url" -w "${WORDLIST:-/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt}" -t 50 -x php,html,txt | tee -a "$scan_results" || return 1

    # Subdomain enumeration
    echo "Performing subdomain enumeration..."
    assetfinder --subs-only "$url" | httprobe | anew | tee -a "$scan_results" || return 1

    # Port scanning
    echo "Performing port scanning..."
    nmap -sV -sC -p- "$url" | tee -a "$scan_results" || return 1

    # Vulnerability scanning
    echo "Performing vulnerability scanning..."
    nikto -h "$url" | tee -a "$scan_results" || return 1

    echo "Web application pentesting completed. Results saved in '$scan_dir' directory."
}

# Function to perform network scanning and enumeration
network_scan() {
    echo "Enter the IP address or range to scan:"
    read ip_range

    # Validate IP input
    if ! validate_ip "$ip_range"; then
        return 1
    fi

    # Dependency check
    if ! command_exists "nmap"; then
        echo "Error: Required tool (nmap) is not installed. Please install it and try again."
        return 1
    fi

    # Create directory for scans
    scan_dir="Scans"
    mkdir -p "$scan_dir"

    # Create file for scan results
    scan_results="$scan_dir/network_scan.txt"
    touch "$scan_results"

    # Additional options
    read -p "Do you want to enable IP spoofing and decoy? (y/n): " spoof_choice
    if [[ $spoof_choice == "y" || $spoof_choice == "Y" ]]; then
        echo "Enter the IP address of the decoy server:"
        read decoy_ip

        # Validate decoy IP input
        if ! validate_ip "$decoy_ip"; then
            echo "Error: Invalid decoy IP address. Exiting."
            return 1
        fi

        # Enable IP spoofing and decoy
        iptables -t nat -A PREROUTING -s "$decoy_ip" -j ACCEPT
        iptables -t nat -A PREROUTING -s ! "$decoy_ip" -j DNAT --to-destination "$decoy_ip"
    fi

    # OS detection
    echo "Performing OS detection..."
    nmap -O -v "$ip_range" | tee -a "$scan_results" || return 1

    # Port scanning
    echo "Performing port scanning..."
    nmap -sV -sC -p- "$ip_range" | tee -a "$scan_results" || return 1

    # Vulnerability scanning
    echo "Performing vulnerability scanning..."
    nmap -sV --script vuln "$ip_range" | tee -a "$scan_results" || return 1

    echo "Network scanning and enumeration completed. Results saved in '$scan_dir' directory."
}

# Main script execution
echo "Select the type of pentesting:"
echo "1. Web application pentesting"
echo "2. Network scanning and enumeration"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1) web_app_pentest ;;
    2) network_scan ;;
    *) echo "Error: Invalid choice. Exiting."; exit 1 ;;
esac
