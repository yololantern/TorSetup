read -p "Enter your Tor node nickname: " nickname
read -p "Enter your email address: " contact_info
read -p "Enter your monthly allotted bandwidth in GB: " bandwidth
bandwidth=${bandwidth:-1000}

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nyx and other necessary packages
sudo apt install nyx apt-transport-https unattended-upgrades apt-listchanges -y

# Configures unattended-upgrades
config_file="/etc/apt/apt.conf.d/50unattended-upgrades"

# Check if the file exists before proceeding
if [ -f "$config_file" ]; then
    # Backup the original file before making changes
    cp "$config_file" "$config_file.bak"
    
    # Replace the block of code in the file
    sed -i '/Unattended-Upgrade::Allowed-Origins {/,/};/d' "$config_file"
    cat <<EOF >> "$config_file"
Unattended-Upgrade::Allowed-Origins {
  "\${distro_id}:\${distro_codename}-security";
  "TorProject:\${distro_codename}";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::Automatic-Reboot "true";
EOF

    echo "Block of code replaced successfully."
else
    echo "Config file not found."
fi

# Auto-detect Debian version
# debianversion=$(cat /etc/debian_version | cut -d'/' -f1)
# echo "Auto-detected Debian version is ${debianversion}"

# Adds tor project files to update list
# echo "Setting up your Tor sources file with your Debian version: $debianversion"
cat <<EOL | sudo tee -a /etc/apt/sources.list.d/tor.list
deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org focal main
deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org focal main
EOL

sudo apt update
sudo apt-get install tor -y

# Add the GPG Key
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

# Configure Tor
echo "Setting up Tor with nickname: $nickname, contact info: $contact_info, bandwidth: $bandwidth GB"
sudo sed -i 's/#SOCKSPort 9050/SOCKSPort 0.0.0.0:9050/' /etc/tor/torrc
cat <<EOL | sudo tee -a /etc/tor/torrc
Nickname $nickname
ContactInfo $contact_info
ORPort 443 
ExitRelay 0
SocksPort 0
## BANDWIDTH
## The config below has a maximum of ${bandwidth} GB
## (up/down) per month, starting on the 1st 
## at midnight
AccountingMax ${bandwidth} GB
AccountingStart month 1 0:00
## MONITORING

ControlPort 9051
CookieAuthentication 1
EOL

# Restart Tor service
sudo systemctl enable tor
sudo systemctl restart tor

# Display Tor status
sudo systemctl status tor
