#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set non-interactive frontend to bypass prompts
export DEBIAN_FRONTEND=noninteractive

# Update and Install dependencies
echo "Updating package lists..."
sudo apt-get update

# Download Telegraf
echo "Downloading Telegraf..."
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.27.1-1_amd64.deb

# Install Telegraf
echo "Installing Telegraf..."
sudo dpkg -i telegraf_1.27.1-1_amd64.deb

# Navigate to Telegraf configuration directory
echo "Navigating to /etc/telegraf..."
cd /etc/telegraf

# Remove default configuration
echo "Removing default config..."
sudo rm -f telegraf.conf

# Create custom telegraf.conf
echo "Creating custom telegraf.conf..."
sudo tee telegraf.conf > /dev/null <<EOF
# Agent Configuration
[agent]
  interval = "5s"
  flush_interval = "5s"
  hostname = "$INFLUX_HOSTNAME"

# Output Plugin for InfluxDB
[[outputs.influxdb_v2]]
  urls = ["$INFLUX_URL"]
  token = "$INFLUX_TOKEN"
  organization = "$INFLUX_ORG"
  bucket = "$INFLUX_BUCKET_VM"

# Read metrics about cpu usage
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = true

# Read metrics about disk IO by device
[[inputs.diskio]]

# Read metrics about memory usage
[[inputs.mem]]

[[inputs.processes]]

[[inputs.system]]
EOF

# Configure telegraf service
echo "Configuring telegraf service..."
sudo tee /etc/systemd/system/telegraf.service > /dev/null <<EOF
[Service]
EnvironmentFile=/root/.env
ExecStart=/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
EOF

# Restart Telegraf service
echo "Restarting Telegraf service..."
sudo systemctl daemon-reload
sudo service telegraf restart

echo "Telegraf installation and configuration complete!"