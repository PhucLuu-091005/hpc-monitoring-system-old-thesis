#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set non-interactive frontend to bypass prompts
export DEBIAN_FRONTEND=noninteractive

# Update and Install dependencies
echo "Updating package lists..."
sudo apt-get update

# Check if nvidia-smi is available
echo "Verifying NVIDIA drivers..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "WARNING: nvidia-smi not found. Please install NVIDIA drivers first."
    echo "Run: sudo apt install -y nvidia-driver-525"
    exit 1
fi

nvidia-smi
echo "NVIDIA drivers verified successfully."

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

# Load environment variables
echo "Loading environment variables..."
set -a
source <(sudo cat /root/.env)
set +a

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

# Read NVIDIA GPU metrics
[[inputs.nvidia_smi]]
  bin_path = "/usr/lib/wsl/lib/nvidia-smi"
  timeout = "5s"
EOF

# Configure telegraf service
echo "Configuring telegraf service..."
sudo tee /etc/systemd/system/telegraf.service > /dev/null <<EOF
[Service]
EnvironmentFile=/root/.env
ExecStart=/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
EOF

# Add permission for Telegraf to reach NVIDIA SMI
sudo usermod -aG video telegraf

# Restart Telegraf service
echo "Restarting Telegraf service..."
sudo systemctl daemon-reload
sudo systemctl restart telegraf
sudo systemctl status telegraf --no-pager -l
echo "Telegraf installation and configuration complete!"

echo "Checking NVIDIA SMI plugin..."
sudo telegraf --config /etc/telegraf/telegraf.conf --input-filter nvidia_smi --test