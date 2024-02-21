#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Tor, Nyx, and other necessary packages
sudo apt install tor nyx unattended-upgrades -y

# Prompt user for nickname, contact info, and monthly bandwidth
read -p "Enter your Tor node nickname: " nickname
read -p "Enter your email address: " contact_info
read -p "Enter your monthly allotted bandwidth in GB (default is 1000): " bandwidth
bandwidth=${bandwidth:-1000}

# Configure Tor
echo "Setting up Tor with nickname: $nickname, contact info: $contact_info, bandwidth: $bandwidth GB"
sudo sed -i 's/#SOCKSPort 9050/SOCKSPort 0.0.0.0:9050/' /etc/tor/torrc
cat <<EOL | sudo tee -a /etc/tor/torrc
Nickname $nickname
ContactInfo $contact_info
RelayBandwidthRate ${bandwidth} GB
RelayBandwidthBurst 1 GB
EOL

# Configure Unattended-Upgrades
cat <<EOF | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
};

Unattended-Upgrade::Package-Blacklist {
    // Disable specific packages from being automatically updated (if needed)
};

Unattended-Upgrade::Mail "";
Unattended-Upgrade::MailOnlyOnError "false";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

EOF

# Configure automatic updates for unattended-upgrades
cat <<EOF | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Restart unattended-upgrades service
sudo systemctl restart unattended-upgrades

echo "Unattended-upgrades installed and configured successfully."

# Restart Tor service
sudo systemctl restart tor

# Display Tor status
sudo systemctl status tor
