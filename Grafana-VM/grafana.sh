#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update system packages
echo "Updating package lists..."
sudo apt update

# Install dependencies for Grafana
echo "Installing dependencies..."
sudo apt-get install -y adduser libfontconfig1 musl

# Download Grafana .deb package
echo "Downloading Grafana..."
wget https://dl.grafana.com/oss/release/grafana_11.2.0_amd64.deb

# Install Grafana
echo "Installing Grafana..."
sudo dpkg -i grafana_11.2.0_amd64.deb

# Start Grafana service
echo "Starting Grafana service..."
sudo service grafana-server start

# Check the status of Grafana service
echo "Checking Grafana service status..."
sudo service grafana-server status

echo "Grafana installation and setup complete!"
