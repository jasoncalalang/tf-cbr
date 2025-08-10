#!/bin/bash

# User data script for CBR test Ubuntu VSI
# Basic configuration and setup for testing

# Update the system
apt-get update -y
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}

# Install basic packages for testing
apt-get install -y \
    nginx \
    curl \
    wget \
    net-tools \
    htop \
    unzip

# Configure nginx for testing
systemctl enable nginx
systemctl start nginx

# Create a simple test page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>CBR Test Server</title>
</head>
<body>
    <h1>CBR Test Ubuntu Server</h1>
    <p>Hostname: ${hostname}</p>
    <p>Server is running and accessible</p>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Configure firewall (ufw) - allow SSH, HTTP, HTTPS, and ICMP
ufw --force enable
ufw allow ssh
ufw allow http
ufw allow https
ufw allow out 53
ufw allow in on lo
ufw allow out on lo

# Log the completion
echo "$(date): CBR test server setup completed" >> /var/log/user-data.log