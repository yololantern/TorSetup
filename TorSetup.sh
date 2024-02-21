#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Tor, Nyx, and other necessary packages
sudo apt install tor nyx unattended-upgrades -y

# Prompt user for nickname, contact info, and monthly bandwidth
read -p "Enter your Tor node nickname: " nickname
read -p "Enter your contact info: " contact_info
read -p "Enter your monthly allotted bandwidth in GB (default is 1000): " bandwidth
bandwidth=${bandwidth:-1000}

# Configure Tor
echo "Setting up Tor with nickname: $nickname, contact info: $contact_info, bandwidth: $bandwidth GB"
sudo sed -i 's/#SOCKSPort 9050/SOCKSPort 0.0.0.0:9050/' /etc/tor/torrc
cat <<EOL | sudo tee -a /etc/tor/torrc
Nickname $nickname
ContactInfo $contact_info
RelayBandwidthRate ${bandwidth} GB
RelayBandwidthBurst $((2 * $bandwidth)) GB
UnattendedUpgrades true
EOL

# Restart Tor service
sudo systemctl restart tor

# Display Tor status
sudo systemctl status tor
